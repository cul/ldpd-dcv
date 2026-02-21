import { Outlet, useLocation, useParams } from "react-router-dom";
import SitesLayoutNavbar from "./sites-layout-navbar";
import { Container } from "react-bootstrap";


const SitesLayout = () => {
  const { pathname } = useLocation();
  const { slug } = useParams();

  // Don't show navbar on subsite dashboard page
  const showNav = pathname !== `/sites/${slug}`;
  console.log(location.pathname)
  console.log(showNav)

  return (
    <Container fluid className="border rounded border-info-subtle">
      {showNav && <SitesLayoutNavbar />}
      <Outlet />
    </Container>
  );
};

export default SitesLayout;
