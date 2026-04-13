import { Container, Nav, Navbar, NavDropdown } from "react-bootstrap";
import { Link } from "react-router";

import { navigatorToRailsRoute } from "@/features/sites/utils/routing-utils";
import { useCurrentUserSuspense } from "@/lib/authentication";
import { ROLES } from "@/lib/authorization";
import { useSitesSuspense } from "@/features/sites/api/get-sites";


const MainNavBar = () => {
  const { permissions: { role } } = useCurrentUserSuspense();
  const sites = useSitesSuspense();
  
  return (
    <Navbar className="bg-dark-subtle">
      <Container>
        <Navbar.Brand href="/">DLC Home</Navbar.Brand>
        <Nav>
          <Nav.Item>
            <Nav.Link as={Link} to='/'>
              DLC Admin Homepage
            </Nav.Link>
          </Nav.Item>
          <Nav.Item>
            {role === ROLES.EDITOR &&
              <NavDropdown title="Your Subsites" id="main-nav-subsites-dropdown" align="end">
                {sites.map((site, i) => (
                  <NavDropdown.Item key={i} as={Link} to={`/sites/${site.slug}`}>{site.title}</NavDropdown.Item>
                ))}
                <NavDropdown.Divider />
                <NavDropdown.Item key={sites.length+1} as={Link} to="/sites">View all</NavDropdown.Item>
              </NavDropdown>
            }
            {role === ROLES.ADMIN &&
              <Nav.Link as={Link} to="/sites">
              DLC Subsites List
            </Nav.Link>}
          </Nav.Item>
          <Nav.Item>
            <NavDropdown title="Help" align="end">
              <NavDropdown.Item onClick={navigatorToRailsRoute('about')}>About DLC</NavDropdown.Item>
              <NavDropdown.Item href="https://library.columbia.edu/services/askalibrarian.html">Ask A Librarian</NavDropdown.Item>
              <NavDropdown.Item href="">Suggestions & Feedback (wip)</NavDropdown.Item>
              <NavDropdown.Item href="https://hours.library.columbia.edu">Library Hours</NavDropdown.Item>
              <NavDropdown.Item href="https://library.columbia.edu/libraries/map.html?location=culis">Maps & Locations</NavDropdown.Item>
              <NavDropdown.Item href="https://resolver.library.columbia.edu/lweb0208">Terms of Use</NavDropdown.Item>
            </NavDropdown>
          </Nav.Item>
          <Nav.Item>
            <Nav.Link onClick={navigatorToRailsRoute('sign_out')}>Log Out</Nav.Link>
          </Nav.Item>
        </Nav>

      </Container>
    </Navbar>
  );
};

export default MainNavBar;