import { navigatorToRailsRoute, formatDateRelative } from "@/lib/utils";
import { Form, Row, Col, Button } from "react-bootstrap";
import { FieldArrayWithId, UseFieldArrayRemove, UseFormRegister } from "react-hook-form";

import { SitePagesGeneralFormValues } from "../site-pages-general-form";


type SitePagesGeneralFormRowProps = {
  slug: string;
  field: FieldArrayWithId<SitePagesGeneralFormValues, "pages", "id">;
  index: number;
  register: UseFormRegister<SitePagesGeneralFormValues>;
  remove: UseFieldArrayRemove;
}

const SitePagesGeneralFormRow = ({ slug, field, index, register, remove}: SitePagesGeneralFormRowProps ) => {
  return (

    <div key={field.id} className={`p-3 rounded ${index % 2 === 0 ? 'subtle-light-blue-background' : ''}`}>
      <Row key={field.id}>
        <Col xs={3} md={3} className="text-end pe-3 pt-2">
          <span className="text-muted">/{field.pageSlug}</span>
        </Col>
        <Col xs={3} md={4}>
          <Form.Control {...register(`pages.${index}.title` as const, {
            setValueAs: (value: string) => value.trim(),
          })} placeholder="Page title" />
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
  )
}

export default SitePagesGeneralFormRow;