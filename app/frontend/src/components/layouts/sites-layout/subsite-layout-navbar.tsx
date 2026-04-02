import { useMemo } from "react";
import { Container, Nav, Navbar } from "react-bootstrap";
import { useLocation, useParams } from "react-router";

import SubsiteLayoutNavLink from "@/components/layouts/sites-layout/subsite-layout-navlink";

const SitesLayoutNavBar = () => {
  const { pathname } = useLocation();
  const { slug } = useParams();
  const basePath = `/sites/${slug}`;

  const activeTab = useMemo(()=>{
    return `/admin${pathname}`
  }, [pathname]);
  console.log('active tab '+ activeTab)
 
  if (!slug) throw Error("Route error: Could not determine subsite");

  return (
    <Navbar className="bg-info-subtle">
      <Container>
        <Nav variant="pills" fill style={{flex: 1}}>
          
          <Nav.Item >
            {/* Links that lead to the Rails app use regular anchor tag */}
            <Nav.Link href={`/${slug}`} className="text-secondary">View Site</Nav.Link>
          </Nav.Item>

          <SubsiteLayoutNavLink basepath={basePath} route={""} activeTab={activeTab}>
              Subsite Dashboard
          </SubsiteLayoutNavLink>

          <SubsiteLayoutNavLink basepath={basePath} route={"/site-properties"} activeTab={activeTab}>
              Site Properties
          </SubsiteLayoutNavLink>

          <SubsiteLayoutNavLink basepath={basePath} route={"/pages"} activeTab={activeTab}>
              Edit Site Pages
          </SubsiteLayoutNavLink>

          <SubsiteLayoutNavLink basepath={basePath} route={"/site-scope"} activeTab={activeTab}>
              Edit Site Scope
          </SubsiteLayoutNavLink>

          <SubsiteLayoutNavLink basepath={basePath} route={"/search-configuration"} activeTab={activeTab}>
              Configure Site Search
          </SubsiteLayoutNavLink>

        </Nav>
      </Container>
    </Navbar>
  );
};

export default SitesLayoutNavBar;