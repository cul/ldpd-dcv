import { Container, Nav, Navbar, NavDropdown } from "react-bootstrap";

import { navigatorToRailsRoute } from "@/features/sites/utils/routing-utils";

const MainNavBar = () => {
  return (
    <Navbar className="bg-dark-subtle">
      <Container>
        <Navbar.Brand href="/">DLC Home</Navbar.Brand>
        <Nav>
          {/* <Navbar.Toggle aria-controls="main-nav-help-dropdown" /> */}
          <NavDropdown title="Help" id="main-nav-help-dropdown" align="end">
            <NavDropdown.Item onClick={navigatorToRailsRoute('about')}>About DLC</NavDropdown.Item>
            <NavDropdown.Item href="https://library.columbia.edu/services/askalibrarian.html">Ask A Librarian</NavDropdown.Item>
            <NavDropdown.Item href="">Suggestions & Feedback (wip)</NavDropdown.Item>
            <NavDropdown.Item href="https://hours.library.columbia.edu">Library Hours</NavDropdown.Item>
            <NavDropdown.Item href="https://library.columbia.edu/libraries/map.html?location=culis">Maps & Locations</NavDropdown.Item>
            <NavDropdown.Item href="https://resolver.library.columbia.edu/lweb0208">Terms of Use</NavDropdown.Item>
          </NavDropdown>
          <Nav.Link onClick={navigatorToRailsRoute('sign_out')}>Log Out</Nav.Link>
        </Nav>

      </Container>
    </Navbar>
  );
};

export default MainNavBar;