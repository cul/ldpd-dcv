import React from 'react';
import FormAccordion from "@/components/ui/forms/form-accordion";
import { Accordion, Button, Col, Container, Form, Row, Stack, Image } from "react-bootstrap";
import { mUpdateSite } from "../../api/update-site";
import { useFieldArray, useForm } from "react-hook-form";
import { useSite, useSiteSuspense } from "../../api/get-site";
import InfoTooltip from "@/components/ui/forms/info-tooltip";
import { sitePropertiesTooltipMessage } from "../../utils";
import { useSubmit } from "react-router-dom";
import { useSites } from "@/features/sites/api/get-sites";
import SaveButton from '@/components/ui/forms/save-button';
import { api } from '@/lib/api-client';
import { Site } from '@/types/api';
import { useQueryClient } from '@tanstack/react-query';

type PortraitLayoutImageFormValues = {
  pids: { value: string}[];
};

const PortraitLayoutImagesForm = ({ initialData }: {initialData: PortraitLayoutImageFormValues }) => {
  const mutation = mUpdateSite();
  const { register, handleSubmit, control } = useForm<PortraitLayoutImageFormValues>({
    defaultValues: initialData,
    mode: 'all',
    disabled: mutation.status === 'pending',
  });
  const { fields, append, remove} = useFieldArray({
    name: 'pids',
    control,
  });

  // TODO : type annotation for data
  const submitHandler = (data: any) => {
    console.log(data);
  // todo: PATCH on submit
  }

  return (
    <Form onSubmit={handleSubmit(submitHandler)}>
      <Stack gap={3}>

        {fields.map((field, index) => (
          <Row key={field.id}>
            <Col xs={10}>
              <Form.Control {...register(`pids.${index}.value` as const)} />
            </Col>
            <Col xs={2}>

              <Button disabled={(fields.length === 1)} type='button' onClick={() => remove(index)} className="btn btn-danger">Remove image PID</Button>
            </Col>
          </Row>
        ))}
        <Button
          type='button'
          onClick={()=> append({ value: ''})}
          className='w-25 btn btn-success'
        >Add a new image PID</Button>

        <SaveButton />

      </Stack>
    </Form>
  )
}

const containerStyles: React.CSSProperties = {
  position: 'relative',
  textAlign: 'center',
  width: 'content',
}

const floatingTextStyles: React.CSSProperties = {
  position: 'absolute',
  top: '50%',
  left: '50%',
  transform: 'translate(-50%,-50%)',
  backgroundColor: '#c3c3c3',
  paddingLeft: '0.5em',
  paddingRight: '0.5em',

};

const ImageUploadPreview = ({ slug, type }: { slug: string; type: 'banner' | 'watermark'}) => {
  console.log('image preview for ' + type)
  const site = useSiteSuspense(slug);
  const hasUpload = type === 'banner' ? site.hasBannerImage : site.hasWatermarkImage;
  const imgUrl = type === 'banner' ? site.bannerImageUrl : site.watermarkImageUrl;
  console.log(hasUpload)
  console.log(imgUrl)

  if (hasUpload) return (
    <div style={containerStyles}>
      <a href={imgUrl} target="_blank" download={`${slug}-signature-${type}`}>
        <Image src={imgUrl} className='w-25' style={{ minWidth: '275px'}} rounded />
        <span style={floatingTextStyles}>Download this image</span>
      </a>
    </div>
  )
  // default:
  return (
    <div className="d-flex flex-column my-4 text-align-center">
      <Image src={imgUrl} className='w-25' style={{ minWidth: '275px'}} rounded />
    </div>
  )
}

type SignatureLayoutImagesFormProps = {
  slug: string;
}


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
const SignatureLayoutImagesForm = ({ slug }: SignatureLayoutImagesFormProps) => {
  const site = useSiteSuspense(slug);
  const queryClient = useQueryClient();
  const mutation = mUpdateSite();

  // TODO : type for data
  const submitHandler = async (data: any) => {
    // console.log(data);
    const formData = new FormData();

    formData.append('site[banner]', data?.banner[0]);
    formData.append('site[watermark]', data?.watermark[0]);
    // formData.append('site[site_slug]', site.slug); // slug is required for the URL

    console.log(data.banner[0])
    console.log(formData);

    // todo: invalidate site cache to refresh
    try {
      await fetch(`/api/v1/sites/${site.slug}`, {
        method: 'PATCH',
        body: formData
      })
      .then(() => queryClient.invalidateQueries({queryKey: ['sites']}));
      // const response = await api.patch<{ site: Site}>(`/sites/${site.slug}`, formData)

      console.log("INVALIDATED QUERIES")
    } catch {
      console.error('Error uploading signature image(s)')
    }
    // mutation.mutate(formData);
  }

  const { register, handleSubmit, formState: { errors }} = useForm({
    disabled: mutation.status === 'pending',
  })

  return (
    <Form onSubmit={handleSubmit(submitHandler)}>
      <Stack gap={4}>
        <Form.Group controlId="SignatureLayoutFormBanner" className="d-flex flex-column">
          <Form.Label><h6>Banner Image:</h6></Form.Label>
          <Form.Text>{site.hasBannerImage ? '' : 'You have not uploaded a banner image yet. If you choose the signature layout, the default image will be used.'}</Form.Text>
          <ImageUploadPreview slug={slug} type='banner' />
          <Form.Control type='file' {...register('banner')} />
        </Form.Group>
        <hr />
        <Form.Group controlId="SignatureLayoutFormWatermark" className="d-flex flex-column">
          <Form.Label><h6>Watermark Image:</h6></Form.Label>
          <Form.Text>{site.hasWatermarkImage ? '' : 'You have not uploaded a watermark image yet. If you choose the signature layout, the default image will be used.'}</Form.Text>
          <ImageUploadPreview slug={slug} type='watermark' />
          <Form.Control type='file' {...register('watermark')} />
        </Form.Group>
        <SaveButton />
      </Stack>
    </Form>
  )
}

// Renders the two homepage image forms -- one for portrait and one for signature
const HomepageImagesForms = ({slug}: {slug: string}) => {
  // data needed:
  // - site layout
  // - image_uris
  // - banner image
  // - watermark image
  const site = useSiteSuspense(slug);
  console.log(`${site.layout}-layout`)

  const portraitLayoutImageFormInitialData: PortraitLayoutImageFormValues = { pids: [] };
  site.imageUris.forEach((pid) => portraitLayoutImageFormInitialData.pids.push({ value: pid}) );

  const signatureLayoutImageFormInitialData = null;

  return (
    <Container>
      <p>If you are using the <span className="fw-bold">Portrait</span> or <span className="fw-bold">Signature</span> Layout types, you can manage the images displayed on the site homepage here.</p>
      <Accordion defaultActiveKey={`${site.layout}-layout`}>
        <Accordion.Item eventKey="portrait-layout">
          <Accordion.Header><InfoTooltip fieldName="portraitLayoutImages" lookupFn={sitePropertiesTooltipMessage} />Portrait Layout Images</Accordion.Header>
          <Accordion.Body>
            <PortraitLayoutImagesForm initialData={portraitLayoutImageFormInitialData}/>
          </Accordion.Body>
        </Accordion.Item>
        <Accordion.Item eventKey="signature-layout">
          <Accordion.Header>Signature Layout Images</Accordion.Header>
          <Accordion.Body>
            <SignatureLayoutImagesForm slug={slug}/>
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>
      {/* <FormAccordion header='Portrait Layout Images'>
        <Form>
          hey
        </Form>
      </FormAccordion>
      <FormAccordion header='Signature Layout Images'>
        <Form>
          hey
        </Form>
      </FormAccordion> */}
    </Container>
  )
}

export default HomepageImagesForms;
