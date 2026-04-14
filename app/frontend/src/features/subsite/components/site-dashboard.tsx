import { ReactNode } from "react";
import { Col, Container, Row } from "react-bootstrap";

import { useSiteSuspense } from "../api/get-site";
import CardLink from "@/components/ui/card-link";
import DLCEditorDocsAlert from "@/components/ui/dlc-editor-docs-alert";


const SiteDashboard = ({ slug }: { slug: string; }) : ReactNode => {
  const site = useSiteSuspense(slug);

  return (
    <Container fluid>
      <Container className="mt-4">
        <h1>Welcome to the Subsite Dashboard for <span className="text-info text-uppercase">{site.title}</span></h1>

        <div className="mt-4 ps-4">
          <h3>Choose which aspect of the subsite you would like to manage:</h3>
          <h5 className="text-secondary">(Currently, only the site properties page is available)</h5>
        </div>
      </Container>

      <Container className="my-4">
        <Row>
          <Col md={6}>
            <CardLink to="site-properties" faClass="fa-duotone fa-solid fa-gears" label={"Edit your subsite's general properties"}/>
          </Col>
          <Col md={6}>
            <CardLink to={"/"} label={"Edit the pages of your subsite (not available yet!)"} faClass="fa-duotone fa-solid fa-pencil"/>
          </Col>
        </Row>
        <Row>
          <Col md={6}>
            <CardLink to={"/"} label={"Configure search for your subsite (not available yet!)"} faClass="fa-duotone fa-solid fa-magnifying-glass" />
          </Col>
          <Col md={6}>
            <CardLink to={"/"} label={"Configure permissions for your subsite (not available yet!)"} faClass="a-duotone fa-solid fa-lock" />
          </Col>
        </Row>
      </Container>

      <Container className="mt-5">
        <DLCEditorDocsAlert />
      </Container>

    </Container>
  )
}

export default SiteDashboard;
