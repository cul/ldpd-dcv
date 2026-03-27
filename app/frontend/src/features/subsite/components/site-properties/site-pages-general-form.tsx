import { useEffect, useMemo } from "react";
import { Button, Col, Form, Row, Stack } from "react-bootstrap";
import { useFieldArray, useForm } from "react-hook-form";

import { MutationAlerts } from "@/components/ui/forms/mutation-alerts";
import { usePagesSuspense } from "@/features/pages/api/get-pages";
import { SitePageGeneralData } from "@/types/api";
import SaveButton from "@/components/ui/forms/save-button";
import { formatDateRelative, navigatorToRailsRoute } from "@/lib/utils";
import { useMUpdateSitePages } from "@/features/pages/api/update-page";


type SitePagesGeneralFormValues = {
  pages: SitePageGeneralData[];
}

const SitePagesGeneralForm = ({ slug }: { slug: string }) => {
  // use staleTime: Infinity to prevent background re-fetches from getting server and component state out of sync
  // TODO : handle this better
  const pages = usePagesSuspense(slug, { queryConfig: { staleTime: Infinity } });
  const mUpdate = useMUpdateSitePages(slug);
  const initialData: SitePagesGeneralFormValues = useMemo(() => ({
      pages: pages.map((page) => ({ siteSlug: slug, pageSlug: page.pageSlug, title: page.title, updatedAt: page.updatedAt}))
    }
  ), [slug, pages])

  const { register, handleSubmit, control, reset, formState, formState: { isDirty, isSubmitting, isSubmitSuccessful, errors } } = useForm<SitePagesGeneralFormValues>({
    values: initialData,
    mode: 'all',
  });

  useEffect(() => {
    if (!isSubmitSuccessful) return;
    reset(initialData);
  }, [formState, isSubmitSuccessful, reset, initialData])


  const { fields, remove} = useFieldArray({
    name: 'pages',
    control,
  });

  const submitHandler = async (data: SitePagesGeneralFormValues) => {
    mUpdate.mutate(data.pages);
  }

  return (
    <>
    <p>
      Here you can manage the pages on your site, including the homepage. You can add new pages, edit existing page titles, and remove pages (except for the homepage). To edit page content, click the &quot;Edit Page Content&quot; button for the corresponding page.
    </p>
      <MutationAlerts
        mutation={mUpdate}
        successMessage="Site page(s) updated successfully!"
        errorMessage="Site page(s) could not be updated due to Error"
      />
      <Form onSubmit={handleSubmit(submitHandler)} className="mb-4">
        <Stack gap={3}>

          <Row>
            <Col xs={4} className="text-center fst-italic">
              Page slug
            </Col>
            <Col xs={4} className="text-center fst-italic">
              Page title
            </Col>
          </Row>
          {fields.map((field, index) => {
            return (
              <div className='p-3 rounded' key={field.id} style={{ backgroundColor: index % 2 === 0 ? '#ddecfb' : 'transparent' }}>
                <Row key={field.id}>
                  <Col xs={3} md={3} className="text-end pe-3 pt-2">
                    <span className="text-muted">/{field.pageSlug}</span>
                  </Col>
                  <Col xs={3} md={4}>
                    <Form.Control {...register(`pages.${index}.title` as const)} placeholder="Page title" />
                  </Col>
                  <Col xs={3} md={3}>
                    <Button
                    type="button"
                    onClick={navigatorToRailsRoute(`/${slug}/${field.pageSlug}/edit`)}> {/* TODO - implement React version of page form */}
                      Edit Page Content</Button>
                    <Row className="px-3 fst-italic text-muted" style={{ fontSize: '0.850rem' }}>Last updated: {formatDateRelative(field.updatedAt)}</Row>
                  </Col>
                  <Col xs={3} md={2}>
                  {field.pageSlug !== 'home' &&
                    <Button
                      type='button'
                      onClick={() => remove(index)}
                      className="btn btn-danger">
                        Remove page
                    </Button>
                  }
                  </Col>
                </Row>
              </div>
          )})}
          <Button
            type="button"
            className="btn btn-success w-25"
            onClick={navigatorToRailsRoute(`/${slug}/pages/new`)}>
            {/* // TODO - implement React version of page form */}
            Create a New Page
          </Button>

          <SaveButton disabled={!isDirty || isSubmitting}>
            {isDirty && !isSubmitting && <span className="text-warning fst-italic px-3">(you have unsaved changes)</span>}
          </SaveButton>
        </Stack>
      </Form>
    </>
  )
}

export default SitePagesGeneralForm;