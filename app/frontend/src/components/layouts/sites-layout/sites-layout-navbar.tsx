import { Container, Nav, Navbar, NavDropdown } from "react-bootstrap";

import { navigatorToRailsRoute } from "@/features/sites/utils/routing-utils";
import AuthorizationBoundary from "@/components/auth/authorization-boundary";
import { ROLES } from "@/lib/authorization";
import { useLocation, useParams } from "react-router-dom";
import { useMemo } from "react";

function PillsExample() {
  return (
    <Navbar>

    <Nav justify variant="pills" defaultActiveKey="/home">
      <Nav.Item>
        <Nav.Link href="/home">Active</Nav.Link>
      </Nav.Item>
      <Nav.Item>
        <Nav.Link eventKey="link-1">Option 2</Nav.Link>
      </Nav.Item>
      <Nav.Item>
        <Nav.Link eventKey="disabled" disabled>
          Disabled
        </Nav.Link>
      </Nav.Item>
    </Nav>
    </Navbar>
  );
}

const SitesLayoutNavBar = () => {
  const { pathname } = useLocation();
  const { slug } = useParams();
  const basePath = `/admin/sites/${slug}`;

  const activeTab = useMemo(()=>{
    console.log("pathname is : "+pathname)
    return `/admin${pathname}`
  }, [pathname]);

  if (!slug) throw Error // todo handle this

  //  TODO: add subsections for each subsite management page
  //       - fix navbar
  //       - implement first features: site properties page
  //       -
  return (
    <>
    <Navbar className="bg-info-subtle">
      <Container>
        {/* Match active pill by eventKey (href value is fallback) */}
        {/* Todo:  */}
        <Nav variant="pills" defaultActiveKey={activeTab}>
          <Nav.Link href={`/${slug}`}>View Site</Nav.Link>
          <Nav.Link href={`${basePath}/site-properties`}>Site Properties</Nav.Link>
          <Nav.Link href={`${basePath}/pages`}>Edit Site Pages</Nav.Link>
          <Nav.Link href={`${basePath}/site-scope`}>Edit Site Scope</Nav.Link>
          <Nav.Link href={`${basePath}/search-configuration`}>Configure Site Search</Nav.Link>
        </Nav>
      </Container>
    </Navbar>
    </>
  );
};

export default SitesLayoutNavBar;