import { ReactNode } from "react";
import { Col, Container, Row } from "react-bootstrap";

import { useSiteSuspense } from "../api/get-site"
import CardLink from "@/components/ui/card-link";
import settingsUrl from "@/assets/icons/settings.png";
import magnifyingGlassUrl from "@/assets/icons/magnifying-glass.png"
import pencilUrl from "@/assets/icons/pencil.png"
import lockUrl from "@/assets/icons/padlock-unlock.png"


const SiteDashboard = ({ slug }: { slug: string; }) : ReactNode => {
  const site = useSiteSuspense(slug);

  return (
    <Container fluid>
      <div className="my-4">
        <h1>Welcome to the Subsite Dashboard for <span className="text-info">{site.title}</span></h1>
      </div>

      <h3>Choose which aspect of the subsite you would like to manage:</h3>

      <Container className="my-5">
        <Row>
          <Col md={6}>
            <CardLink to={"/"} label={"Edit your subsite's general properties"} image={settingsUrl} altTxt="icon of three gears" />
          </Col>
          <Col md={6}>
            <CardLink to={"/"} label={"Edit the pages of your subsite"} image={pencilUrl} altTxt="icon of a pencil" />
          </Col>
        </Row>
        <Row>
          <Col md={6}>
            <CardLink to={"/"} label={"Configure search for your subsite"} image={magnifyingGlassUrl} altTxt="icon of a magnifying glass" />
          </Col>
          <Col md={6}>
            <CardLink to={"/"} label={"Configure permissions for your subsite"} image={lockUrl} altTxt="icon of a padlock" />
          </Col>
        </Row>
      </Container>

    </Container>
  )
}

export default SiteDashboard;
