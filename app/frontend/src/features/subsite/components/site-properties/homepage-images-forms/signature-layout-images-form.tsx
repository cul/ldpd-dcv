import { useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { Button, Form, Stack, Alert } from "react-bootstrap";
import { useForm } from "react-hook-form";
import z from "zod";
import { zodResolver } from "@hookform/resolvers/zod";

import { useSiteSuspense } from "@/features/subsite/api/get-site";
import ImageUploadPreview from "./image-upload-preview";
import SaveButton from "@/components/ui/forms/save-button";
import { api } from "@/lib/api-client";


const schema = z.object({
  banner: z.instanceof(FileList)
    .refine((files) => files.length === 0 || (files.length === 1 && files[0].size <= 5 * 1024 * 1024))
    .refine((files) => files.length === 0 || (files[0]?.name.split('.').pop()?.toLowerCase() === 'png'), 'Only PNG files are accepted')
    .optional(),
  watermark: z.instanceof(FileList)
    .refine((files) => files.length === 0 || (files.length === 1 && files[0].size <= 5 * 1024 * 1024))
    .refine((files) => files.length === 0 || (files[0]?.name.split('.').pop()?.toLowerCase() === 'svg'), 'Only SVG files are accepted')
    .optional(),
});

type FormInput = {
  banner?: FileList;
  watermark?: FileList;
};

// This form is sort of peculiar:
// It is an input-only form; we do not render it with initial data, we only allow
// users to upload a new image to replace the existing one (or replace the default).
// This is because we do not store these assets in the database nor do we store the
// relationship between the subsite and these images in the database--
// Instead, the data for 'does this site have a watermark/banner image' and 'which
// image belongs to this site' are determined by whether a file with the right name
// exists in the correct location in the public/ directory.
// E.g., at runtime, Rails checks if 'jay' has images with the right name at
// 'public/images/sites/jay/'.
// The sites API will return watermark- and bannerImageUrl fields set to either the
// existing asset path, or the default asset path. The API also passes along
// hasBanner- and hasWatermarkImage values (from the existing Site model methods).
// Therefore, we have to do some things manually that react hook form + tanstack
// query provides for us in other forms.
const SignatureLayoutImagesForm = ({ slug }: {slug: string}) => {
  const site = useSiteSuspense(slug);
  const queryClient = useQueryClient();
  const [showAlert, setShowAlert] = useState(false);
  const [submissionAlert, setSubmissionAlert] = useState({ isError: false, msg: ''});

  // Because we are not using the mutation cache to trigger updates to the server
  // data, we must manage that logic ourselves. This handler makes a PATCH request
  // to the backend, and if it encounters an error:
  // - validation error (422): display a descriptive error
  // - anything else: render an enclosing error boundary.
  const submitHandler = async (data: FormInput) => {
    try {
      const formData = new FormData();

      if (data?.banner?.length === 0 && data?.watermark?.length === 0) throw Error("You have not uploaded any images.");
      if (data?.banner?.[0]) formData.append('site[banner]', data.banner[0]);
      if (data?.watermark?.[0]) formData.append('site[watermark]', data.watermark[0]);

      await api.patchRaw(`/sites/${site.slug}`, formData);
      setSubmissionAlert({ isError: false, msg: 'Your image has been uploaded and saved.'})
      setShowAlert(true);
      queryClient.invalidateQueries({queryKey: ['sites']});
    } catch(error: unknown){
      if (error instanceof Error) {
        setSubmissionAlert({ isError: true, msg: `There was an error uploading the image: ${error?.message}` })
      } else {
        setSubmissionAlert({ isError: true, msg: 'An unknown error occurred while uploading your image. Please try again.' })
      }
      setShowAlert(true);
    }
  }

  const { register, handleSubmit, formState: { errors }} = useForm<FormInput>({
    resolver: zodResolver(schema)
  });

  const deleteWatermarkHandler = async () => {
    if (!window.confirm("Are you sure you want to delete this image?")) return;
    await api.delete(`/sites/${site.slug}/signature_images/watermark`);
    setSubmissionAlert({ isError: false, msg: 'Your watermark image has been deleted. The default watermark will now be used.'})
    setShowAlert(true);
    queryClient.invalidateQueries({queryKey: ['sites']});
  }

  const deleteBannerHandler = async () => {
    if (!window.confirm("Are you sure you want to delete this image?")) return;
    await api.delete(`/sites/${site.slug}/signature_images/banner`);
    setSubmissionAlert({ isError: false, msg: 'Your banner image has been deleted. The default banner will now be used.'})
    setShowAlert(true);
    queryClient.invalidateQueries({queryKey: ['sites']});
  }

  const getFilenameFromUrl = (url: string) => url.split('/').pop()?.split('?')[0];

  return (
    <>
    { showAlert && (
      <Alert
        variant={submissionAlert.isError ? 'danger' : 'success'}
        dismissible onClose={() => setShowAlert(false)}>
        {submissionAlert.msg}
      </Alert>
    )}
    <Form onSubmit={handleSubmit(submitHandler)}>
      <Stack gap={4}>
        <Form.Group controlId="SignatureLayoutFormBanner" className="d-flex flex-column">
          {/* Clicking a label activates input, so visually hide upload labels */}
          <Form.Label hidden>Banner Image:</Form.Label>
          <div>
            <span className='fw-bold'>Banner image: </span>{site.hasBannerImage ? getFilenameFromUrl(site.bannerImageUrl) : 'using default.'}
          </div>
          <Form.Text>{site.hasBannerImage ? '' : 'You have not uploaded a banner image yet. If you choose the signature layout, the default image will be used.'}</Form.Text>
          <ImageUploadPreview slug={slug} type='banner' />
          <Form.Control type='file' {...register('banner')} />
          {errors && errors.banner && <Form.Text className="text-danger">{errors.banner.message}</Form.Text>}
          {site.hasBannerImage && <Button variant='danger' onClick={deleteBannerHandler}>Delete Banner Image (and use default)</Button>}
        </Form.Group>
        <hr />
        <Form.Group controlId="SignatureLayoutFormWatermark" className="d-flex flex-column">
          {/* Clicking a label activates input, so visually hide upload labels */}
          <Form.Label hidden>Watermark Image:</Form.Label>
          <div>
            <span className='fw-bold'>Watermark image: </span>{site.hasWatermarkImage ? getFilenameFromUrl(site.watermarkImageUrl) : 'using default.'}
          </div>
          <Form.Text>{site.hasWatermarkImage ? '' : 'You have not uploaded a watermark image yet. If you choose the signature layout, the default image will be used.'}</Form.Text>
          <ImageUploadPreview slug={slug} type='watermark' />
          <Form.Control type='file' {...register('watermark')} />
          {errors && errors.watermark && <Form.Text className="text-danger">{errors.watermark.message}</Form.Text>}
          {site.hasWatermarkImage && <Button variant='danger' onClick={deleteWatermarkHandler}>Delete Watermark Image (and use default)</Button>}
        </Form.Group>
        {/* We can't rely on isDirty for enabling/disabling the form, so this button will always be enabled */}
        <SaveButton updatedAt={site.updatedAt} />
      </Stack>
    </Form>
    </>
  )
}

export default SignatureLayoutImagesForm;