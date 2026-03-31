import { useEffect, useMemo } from "react";
import { useFieldArray, useForm } from "react-hook-form";
import { Button, Col, Form, Row, Stack } from "react-bootstrap";

import { useMUpdateSite } from "@/features/subsite/api/update-site";
import SaveButton from "@/components/ui/forms/save-button";
import { SitePortraitImageUris } from "@/types/api";
import { MutationAlerts } from "@/components/ui/forms/mutation-alerts";
import { useSiteSuspense } from "@/features/subsite/api/get-site";


type PortraitLayoutImageFormValues = {
  imageUris: { value: string}[];
};

type PortraitLayoutImageFormProps = {
  slug: string;
}

const PortraitLayoutImagesForm = ({ slug }: PortraitLayoutImageFormProps) => {
  const site = useSiteSuspense(slug);
  const mutation = useMUpdateSite();
  const initialData: PortraitLayoutImageFormValues = useMemo(() => ({
    imageUris: site.imageUris.map((pid) => ({ value: pid }))
  }), [site]);

  const { register, handleSubmit, control, reset, formState: { isDirty, isSubmitting, isSubmitSuccessful } } = useForm<PortraitLayoutImageFormValues>({
    values: initialData,
    mode: 'all',
    disabled: mutation.status === 'pending',
  });

  const { fields, append, remove} = useFieldArray({
    name: 'imageUris',
    control,
  });

  useEffect(() => {
    if (!isSubmitSuccessful) return;
    reset(initialData);
  }, [initialData, isSubmitSuccessful, reset])

  const submitHandler = (data: PortraitLayoutImageFormValues) => {
    const reqBody: SitePortraitImageUris  = {
      slug: slug,
      imageUris: [],
    }
    data.imageUris.forEach((obj: { value: string;}) => reqBody.imageUris.push(obj.value) )
    mutation.mutate(reqBody);
  }

  return (<>
    <MutationAlerts
      mutation={mutation}
      successMessage="Site updated successfully!"
      errorMessage="Site changes could not be saved due to Error"
    />
    <Form onSubmit={handleSubmit(submitHandler)}>
      <Stack gap={3}>

        {fields.map((field, index) => (
          <Row key={field.id}>
            <Col xs={10}>
              <Form.Control {...register(`imageUris.${index}.value` as const)} />
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

        <SaveButton isDirty={isDirty} updatedAt={site.updatedAt} isSubmitting={isSubmitting || mutation.isPending} />

      </Stack>
    </Form>
  </>)
}

export default PortraitLayoutImagesForm ;