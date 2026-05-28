import { useEffect, useMemo } from 'react';
import { Button, Col, Form, Row, Stack } from 'react-bootstrap';
import { useFieldArray, useForm } from 'react-hook-form';

import { MutationAlerts } from '@/components/ui/forms/mutation-alerts';
import { usePagesSuspense } from '@/features/pages/api/get-pages';
import { SitePageGeneralData } from '@/types/api';
import SaveButton from '@/components/ui/forms/save-button';
import { navigatorToRailsRoute } from '@/lib/utils';
import { useMUpdateSitePages } from '@/features/pages/api/update-page';
import SitePagesGeneralFormRow from './site-pages-general-form/site-pages-general-form-row';

export type SitePagesGeneralFormValues = {
  pages: SitePageGeneralData[];
};

const SitePagesGeneralForm = ({ slug }: { slug: string }) => {
  // use staleTime: Infinity to prevent background re-fetches from getting server and component state out of sync
  // TODO : handle this better
  const pages = usePagesSuspense(slug, { queryConfig: { staleTime: Infinity } });
  const mUpdate = useMUpdateSitePages(slug);
  const initialData: SitePagesGeneralFormValues = useMemo(
    () => ({
      pages: pages.map((page) => ({
        siteSlug: slug,
        pageSlug: page.pageSlug,
        title: page.title ?? '', // normalize optional input
        updatedAt: page.updatedAt,
      })),
    }),
    [slug, pages],
  );

  const {
    register,
    handleSubmit,
    control,
    reset,
    formState,
    formState: { isDirty, isSubmitting, isSubmitSuccessful },
  } = useForm<SitePagesGeneralFormValues>({
    values: initialData,
    mode: 'all',
  });

  const { fields, remove } = useFieldArray({
    name: 'pages',
    control,
  });

  const submitHandler = async (data: SitePagesGeneralFormValues) => {
    mUpdate.mutate(data.pages);
  };

  useEffect(() => {
    if (!isSubmitSuccessful) return;
    console.log('resetting!');
    reset(initialData);
  }, [formState, isSubmitSuccessful, reset, initialData]);

  return (
    <>
      <p>
        Here you can manage the pages on your site, including the homepage. You can add new pages,
        edit existing page titles, and remove pages (except for the homepage). To edit page content,
        click the &quot;Edit Page Content&quot; button for the corresponding page.
      </p>
      <MutationAlerts
        mutation={mUpdate}
        successMessage="Site page(s) updated successfully!"
        errorMessage="Site page(s) could not be updated due to Error"
      />
      <Form onSubmit={handleSubmit(submitHandler)} className="mb-4">
        <Stack gap={3}>
          <Row>
            <Col xs={3} className="text-center fst-italic">
              Page slug
            </Col>
            <Col xs={3} className="text-center fst-italic">
              Page title
            </Col>
          </Row>

          {fields.map((field, index) => (
            <SitePagesGeneralFormRow
              key={index}
              slug={slug}
              field={field}
              index={index}
              register={register}
              remove={remove}
            />
          ))}
          <Button
            type="button"
            className="btn btn-success w-25"
            onClick={navigatorToRailsRoute(`/${slug}/pages/new`)}
          >
            {/* // TODO - implement React version of page form */}
            Create a New Page
          </Button>

          <SaveButton isDirty={isDirty} isSubmitting={isSubmitting} />
        </Stack>
      </Form>
    </>
  );
};

export default SitePagesGeneralForm;
