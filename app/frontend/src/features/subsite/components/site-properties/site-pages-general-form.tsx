import { useEffect, useState } from "react";
import { Button, Col, Form, Row, Stack } from "react-bootstrap";
import { FieldArrayWithId, useFieldArray, useForm } from "react-hook-form";

import { MutationAlerts } from "@/components/ui/forms/mutation-alerts";
import { usePagesSuspense } from "@/features/pages/api/get-pages";
import { SitePageGeneralData } from "@/types/api";
import SaveButton from "@/components/ui/forms/save-button";
import { formatDateRelative, navigatorToRailsRoute } from "@/lib/utils";
import { mUpdateSitePages } from "@/features/pages/api/update-page";
import { mDeleteSitePages } from "@/features/pages/api/delete-pages";


type SitePagesGeneralFormValues = {
  pages: SitePageGeneralData[];
}

// This form allows editors to manage some general information about their subsite's pages
// They can:
// - see the list of pages on their subsite, with page slug and title
// - edit the title of existing pages
// - delete existing pages (except for the homepage, which can't be deleted)
// To edit page text, etc., they will need to click the "Edit Page Content" button for the corresponding page, which will take them to a different form (not yet implemented)
// To create a new page, they will need to click the "Create a New Page" button, which will also take them to a different form (not yet implemented)
// N.B.: Basically two types of mutations are possible when a user clicks submit:
//   - update page titles
//   - deletion of pages entirely
// We use form state to track title updates, but use component state to track pages flagged for deletion
// However, because we use react hook forms useFieldArray for convenience, if a user is JUST deleting pages,
// the form will be considered "dirty" due to the change in the field array. To get around this, on submit,
// we check whether there are any meaningful changes to the page titles before we trigger the update mutation (see submitHandler)
// (we cannot combine both actions, because the Site model does not accept nested attributes for pages -- we need separate API endpoints...)
const SitePagesGeneralForm = ({ slug }: { slug: string }) => {
  const pages = usePagesSuspense(slug);
  const mUpdate = mUpdateSitePages(slug);
  const mDelete = mDeleteSitePages(slug);
  const [pagesToDelete, setPagesToDelete] = useState<string[]>([]);
  const initialData: SitePagesGeneralFormValues= { pages: [] };
  pages.forEach((page) => initialData.pages.push({ siteSlug: slug, pageSlug: page.pageSlug, title: page.title, updatedAt: page.updatedAt}));

  const { register, handleSubmit, control, reset, formState, formState: { isDirty, isSubmitting, isSubmitSuccessful, errors } } = useForm<SitePagesGeneralFormValues>({
    defaultValues: initialData,
    mode: 'all',
  });

  // We run the form reset after both a successful submission AND a refetch of new page data--
  useEffect(() => {
    if (!isSubmitSuccessful) return;
    console.log('resetting form with new initial data:', initialData.pages);
    reset(initialData);
    setPagesToDelete([]);
  }, [pages, formState]);


  const { fields, remove} = useFieldArray({
    name: 'pages',
    control,
  });

  // Each page is its own record in the database, so we handle deletion of pages by keeping track of which
  // pages the user has flagged for deletion, and then making a separate API request to delete them
  const handleDeletePage = (field: FieldArrayWithId<SitePagesGeneralFormValues>, index: number) => {
    setPagesToDelete((prev) => [...prev, field.pageSlug]);
    remove(index);
  }

  const submitHandler = async (data: SitePagesGeneralFormValues) => {
    // We only call update if a title has been edited -- but we can't rely on form state because if a user has only deleted pages,
    // the form is considered dirty due to the change in the field array - therefore, check manually
    const hasUpdatedData = data.pages.some((page, index) => {
      const original = formState.defaultValues?.pages?.[index];
      return !original || original.title !== page.title;
    });
    if (hasUpdatedData) {
      console.log('mUpdate pages!')
      await mUpdate.mutateAsync(data.pages);
    }
    if (pagesToDelete.length > 0) {
      console.log('mDelete pages!')
      await mDelete.mutateAsync(pagesToDelete);
    }
  }

  return (
    <>
    <p>
      Here you can manage the pages on your site, including the homepage. You can add new pages, edit existing page titles, and remove pages (except for the homepage). To edit page content, click the "Edit Page Content" button for the corresponding page.
    </p>
    {/*  TODO : instead of multiple mutation alerts, it would be better to combine them */}
      <MutationAlerts
        mutation={mDelete}
        successMessage="Site page(s) deleted successfully!"
        errorMessage="Site page(s) could not be deleted due to Error"
      />
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
                      onClick={() => handleDeletePage(field, index)}
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