import { ReactNode } from "react";
import { Col, Container, Row } from "react-bootstrap";

import { useSiteSuspense } from "../api/get-site";
import CardLink from "@/components/ui/card-link";
import settingsIconUrl from "@/assets/icons/settings.png";
import magnifyingGlassIconUrl from "@/assets/icons/magnifying-glass.png";
import pencilIconUrl from "@/assets/icons/pencil.png";
import lockIconUrl from "@/assets/icons/padlock-unlock.png";


const SiteDashboard = ({ slug }: { slug: string; }) : ReactNode => {
  const site = useSiteSuspense(slug);

  return (
    <Container fluid>
      <Container className="mt-4">
        <h1>Welcome to the Subsite Dashboard for <span className="text-info">{site.title}</span></h1>

        <div className="mt-4 ps-4">
          <h3>Choose which aspect of the subsite you would like to manage:</h3>
          <h5 className="text-secondary">(Currently, only the site properties page is available)</h5>
        </div>
      </Container>

      <Container className="my-4">
        <Row>
          <Col md={6}>
            <CardLink to="site-properties" label={"Edit your subsite's general properties"} image={settingsIconUrl} altTxt="icon of three gears" />
          </Col>
          <Col md={6}>
            <CardLink to={"/"} label={"Edit the pages of your subsite (not available yet!)"} image={pencilIconUrl} altTxt="icon of a pencil" />
          </Col>
        </Row>
        <Row>
          <Col md={6}>
            <CardLink to={"/"} label={"Configure search for your subsite (not available yet!)"} image={magnifyingGlassIconUrl} altTxt="icon of a magnifying glass" />
          </Col>
          <Col md={6}>
            <CardLink to={"/"} label={"Configure permissions for your subsite (not available yet!)"} image={lockIconUrl} altTxt="icon of a padlock" />
          </Col>
        </Row>
      </Container>

    </Container>
  )
}

export default SiteDashboard;
