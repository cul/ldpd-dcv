import { SiteGeneralProperties } from '@/types/api';
import { shouldThrowError } from '@tanstack/react-query';
import * as formik from 'formik';
import  { Formik, ErrorMessage }  from 'formik';
import { Button, Col, Form, Row, Stack } from 'react-bootstrap';
import { Link } from 'react-router-dom';
import * as Yup from 'yup';
import { mUpdateSite } from '../../api/update-site';

// const GeneralPropertiesForm = ( { title, alternativeTitle, palette, layout, searchType, showFacets }: SiteGeneralProperties ) => {
const GeneralPropertiesForm = ( {siteGeneralProperties}: {siteGeneralProperties: SiteGeneralProperties} ) => {
  const mutation = mUpdateSite();

  //  TODO : consider having these values stored on the backend and retrieved by api endpoint
  // (can change the set of options overtime without breaking things in UI)
  enum SitePalette {
    BLUE = 'blue',
    LIGHT = 'light',
    DARK = 'dark',
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

  const schema = Yup.object().shape({
    title: Yup.string().required(),
    alternativeTitle: Yup.string().nullable(),
    palette: Yup.string().required(),
    layout: Yup.string().required(),
    searchType: Yup.string().required(),
  });

  return (
    <Formik
      validationSchema={schema}
      onSubmit={(values, { setSubmitting }) => {
        console.log("submitting...")
        // setTimeout(() => { setSubmitting(false)}, 2000);
        console.log(values);
        mutation.mutate(values);
      }}
      // TODO : should we throw an error if initial values can't be loaded from the props? I think so
      initialValues={ siteGeneralProperties || {
        title: 'title',
        alternativeTitle: '',
        palette: SitePalette.DEFAULT,
        layout: SiteLayout.DEFAULT,
        searchType: SearchType.CATALOG,
      }}
      >
        {({ handleSubmit, handleChange, setFieldTouched, handleBlur, values, touched, errors, isValid, isSubmitting}) => {
          const isFormTouched = Object.keys(touched).length > 0;
          console.log(JSON.stringify(touched))
          console.log('isformtouched:', isFormTouched, 'is valid:', isValid)
          console.log('errors')
          console.log(JSON.stringify(errors))
          if (isSubmitting) return <div>Submitting...</div>
          return (
          <Form onSubmit={handleSubmit}>
            <Stack gap={4}>

            <Form.Group as={Row}>
              <Form.Label as={Col} xs={2}>Title:</Form.Label>
              <Col xs={10}>
                <Form.Control
                  disabled
                  type="text"
                  name="title"
                  value={values.title}
                  onChange={handleChange}
                />
                <Form.Text>You can not edit this value.</Form.Text> {/* TODO: confirm correctness? */}
              </Col>
            </Form.Group>

            <Form.Group as={Row}>
              <Col xs={2}>
                <Form.Label>Alternative Title:</Form.Label>
              </Col>
              <Col xs={10}>
                <Form.Control
                  type="text"
                  name="alternativeTitle"
                  value={values.alternativeTitle}
                  onChange={handleChange}
                  onBlur={handleBlur}
                  isValid={touched.alternativeTitle && !errors.alternativeTitle}
                />
                {touched.title && errors.title && (
                  <Form.Control.Feedback type="invalid">{errors.title}</Form.Control.Feedback>
                )}
              </Col>
            </Form.Group>

            <Form.Group as={Row}>
              <Col xs={2}>
                <Form.Label>Site Palette:</Form.Label>
              </Col>
              <Col xs={10}>
                <Form.Select
                  aria-label="Select a site palette"
                  name="palette"
                  value={values.palette}
                  onChange={(e) => {
                    handleChange(e);
                    handleBlur(e);
                  }}
                  isValid={touched.palette && !errors.palette}
                  isInvalid={touched.palette && !!errors.palette}
                >
                  <option disabled>Select a site palette</option>
                  <option value={SitePalette.DEFAULT}>DLC Default</option>
                  <option value={SitePalette.DARK}>Dark</option>
                  <option value={SitePalette.LIGHT}>Light</option>
                  <option value={SitePalette.BLUE}>Blue</option>

                </Form.Select>
                {touched.palette && errors.palette && (
                  <Form.Control.Feedback type="invalid">{errors.palette}</Form.Control.Feedback>
                )}
              </Col>
            </Form.Group>

            <Form.Group as={Row}>
              <Col xs={2}>
                <Form.Label>Site Layout:</Form.Label>
              </Col>
              <Col xs={10}>
                <Form.Select
                  aria-label="Select a site layout"
                  name="layout"
                  value={values.layout}
                  onChange={(e) => {
                    handleChange(e);
                    handleBlur(e);
                  }}
                  isValid={touched.layout && !errors.layout}
                  isInvalid={touched.layout && !!errors.layout}
                >
                  <option disabled>Select a site layout</option>
                  <option value={SiteLayout.DEFAULT}>DLC Default</option>
                  <option value={SiteLayout.PORTRAIT}>Portrait</option>
                  <option value={SiteLayout.GALLERY}>Gallery</option>
                  <option value={SiteLayout.REPOSITORIES}>Repositories</option>
                  <option value={SiteLayout.SIGNATURE}>Signature</option>
                </Form.Select>
                {touched.layout && errors.layout && (
                  <Form.Control.Feedback type="invalid">{errors.layout}</Form.Control.Feedback>
                )}
              </Col>
            </Form.Group>

            <Form.Group as={Row}>
              <Col xs={2}>
                <Form.Label>Search Type:</Form.Label>
              </Col>
              <Col xs={10}>
                <Form.Select
                  aria-label="Select a search type"
                  name="searchType"
                  value={values.searchType}
                  onChange={(e) => {
                    handleChange(e);
                    handleBlur(e);
                  }}
                  isValid={touched.searchType && !errors.searchType}
                  isInvalid={touched.searchType && !!errors.searchType}
                >
                  <option disabled>Select a search type</option>
                  <option value={SearchType.CATALOG}>Catalog</option>
                  <option value={SearchType.LOCAL}>Local</option>
                  <option value={SearchType.CUSTOM}>Custom</option>
                  <option value={SearchType.REPOSITORIES}>Repositories</option>
                </Form.Select>
                {touched.searchType && errors.searchType && (
                  <Form.Control.Feedback type="invalid">{errors.searchType}</Form.Control.Feedback>
                )}
              </Col>
            </Form.Group>

            <Link to="search-config">Edit facet search config</Link>

            <Button type="submit" className="w-25" disabled={!isValid || !isFormTouched} >Save Changes</Button>

            </Stack>
          </Form>
        )}}
      </Formik>
  )
}

export default GeneralPropertiesForm;