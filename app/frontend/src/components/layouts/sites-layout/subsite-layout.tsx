import { Outlet } from "react-router-dom";
import SitesLayoutNavbar from "./subsite-layout-navbar";
import { Col, Container, Row } from "react-bootstrap";
import BackButton from "@/components/ui/back-button";


const SubSiteLayout = () => {
  // const { pathname } = useLocation();
  // const { slug } = useParams();

  // TODO: Should we show the navbar on the dashboard page?
  const showNav = true; //pathname !== `/sites/${slug}`;

  return (
    // <Container fluid className="border rounded border-info-subtle">
    <>
      {showNav && <SitesLayoutNavbar />}
      <Row>
        <Col xs={2} className="text-center">
          <BackButton />
        </Col>
        <Col xs={8}>
          <Outlet />
        </Col>
      </Row>
    {/* </Container> */}
    </>
  );
};

export default SubSiteLayout ;
