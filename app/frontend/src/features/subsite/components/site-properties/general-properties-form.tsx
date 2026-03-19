import { SiteGeneralProperties } from '@/types/api';
import { Col, Form, Row, Stack } from 'react-bootstrap';
import { Link } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from 'zod';

import { useMUpdateSite } from '../../api/update-site';
import { getSiteGeneralProperties, sitePropertiesTooltipMessage } from '../../utils';
import InfoTooltip from '@/components/ui/forms/info-tooltip';
import FormErrorMsg from '@/components/ui/forms/form-error-msg';
import { useSiteSuspense } from '../../api/get-site';
import SaveButton from '@/components/ui/forms/save-button';
import { MutationAlerts } from '@/components/ui/forms/mutation-alerts';


const schema = z.object({
  slug: z.string().min(1),
  title: z.string().trim().min(1, "Title is required"),
  alternativeTitle: z.string().optional(),
  palette: z.string().min(1),
  layout: z.string().min(1),
  searchType: z.string().min(1),
})

//  TODO : consider having these values stored on the backend and retrieved by api endpoint
// (can change the set of options overtime without breaking things in UI)
enum SitePalette {
  BLUE = 'blue',
  LIGHT = 'monochrome',
  DARK = 'monochromeDark',
  DEFAULT = 'default',
}
enum SiteLayout {
  PORTRAIT = 'portrait',
  GALLERY = 'gallery',
  REPOSITORIES = 'repositories',
  SIGNATURE = 'signature',
  DEFAULT = 'default',
}
enum SearchType {
  CATALOG = 'catalog',
  LOCAL = 'local',
  CUSTOM = 'custom',
  REPOSITORIES = 'repositories',
}


const GeneralPropertiesForm = ( { slug}: {slug: string} ) => {
  const mutation = useMUpdateSite();
  const site = useSiteSuspense(slug);
  const siteGeneralProperties = getSiteGeneralProperties(site);
  const submitHandler = (data: SiteGeneralProperties) => mutation.mutate(data);
  const {
    register,
    handleSubmit,
    formState: { errors, isDirty }
  } = useForm<SiteGeneralProperties>({
    defaultValues: siteGeneralProperties,
    resolver: zodResolver(schema),
    mode: 'all',
    disabled: mutation.status === 'pending', // disable form until PATCH action is complete
   });


  return (
    <>
     <MutationAlerts
        mutation={mutation}
        successMessage="Site updated successfully!"
        errorMessage="Site changes could not be saved due to Error"
      />
    <Form onSubmit={handleSubmit(submitHandler)}>
      <Stack gap={3}>

        <Form.Group as={Row} controlId="generalPropertiesFormTitle">
          <Col xs={2}>
            <InfoTooltip fieldName='title' lookupFn={sitePropertiesTooltipMessage} />
            <Form.Label>Title:</Form.Label>
          </Col>
          <Col xs={10}>
            <Form.Control {...register('title', { disabled: true })} /> {/* plaintext readOnly  */}
            <Form.Text className="px-2">You can not edit this value in DLC.</Form.Text>
            <FormErrorMsg msg={errors.title?.message} />
          </Col>
        </Form.Group>

        <Form.Group as={Row} controlId="generalPropertiesFormAlternativeTitle">
          <Col xs={2}>
            <InfoTooltip fieldName='alternativeTitle' lookupFn={sitePropertiesTooltipMessage} />
            <Form.Label>Alternative Title:</Form.Label>
          </Col>
          <Col xs={10}>
            <Form.Control {...register('alternativeTitle')} placeholder="Alternative Title" />
            <Form.Text className="px-2">Setting an alternative title is optional.</Form.Text>
          </Col>
        </Form.Group>

        <Form.Group as={Row} controlId="generalPropertiesFormPalette">
          <Col xs={2}>
            <InfoTooltip fieldName='palette' lookupFn={sitePropertiesTooltipMessage} />
            <Form.Label>Site Palette:</Form.Label>
          </Col>
          <Col xs={10}>
            <Form.Select
              {...register('palette')}
              aria-label="Select a site palette" >
              <option disabled>Select a site palette</option>
              <option value={SitePalette.DEFAULT}>DLC Default</option>
              <option value={SitePalette.DARK}>Dark</option>
              <option value={SitePalette.LIGHT}>Light</option>
              <option value={SitePalette.BLUE}>Blue</option>
            </Form.Select>
            </Col>
        </Form.Group>

        <Form.Group as={Row} controlId="generalPropertiesFormLayout">
          <Col xs={2}>
            <InfoTooltip fieldName='layout' lookupFn={sitePropertiesTooltipMessage} />
            <Form.Label>Site Layout:</Form.Label>
          </Col>
          <Col xs={10}>
            <Form.Select
              {...register('layout')}
              aria-label="Select a site layout"
            >
              <option disabled>Select a site layout</option>
              <option value={SiteLayout.DEFAULT}>DLC Default</option>
              <option value={SiteLayout.PORTRAIT}>Portrait</option>
              <option value={SiteLayout.GALLERY}>Gallery</option>
              <option value={SiteLayout.REPOSITORIES}>Repositories</option>
              <option value={SiteLayout.SIGNATURE}>Signature</option>
            </Form.Select>
          </Col>
        </Form.Group>

        <Form.Group as={Row} controlId="generalPropertiesFormSearchType">
          <Col xs={2}>
          <div className="d-flex flex-column">
            <div>
              <InfoTooltip fieldName='searchType' lookupFn={sitePropertiesTooltipMessage} />
              <Form.Label>Search Type:</Form.Label>
            </div>
            <Link to="search-config" className="fs-6 fw-light">Edit facet search config</Link>
          </div>
          </Col>
          <Col xs={10}>
            <Form.Select
              {...register('searchType')}
              aria-label="Select a search type"
            >
              <option disabled>Select a search type</option>
              <option value={SearchType.CATALOG}>Catalog</option>
              <option value={SearchType.LOCAL}>Local</option>
              <option value={SearchType.CUSTOM}>Custom</option>
              <option value={SearchType.REPOSITORIES}>Repositories</option>
            </Form.Select>
          </Col>
        </Form.Group>

        <div>
          <SaveButton isDirty={isDirty} updatedAt={site.updatedAt} />
        </div>

      </Stack>
    </Form>
    </>
  )
}

export default GeneralPropertiesForm;