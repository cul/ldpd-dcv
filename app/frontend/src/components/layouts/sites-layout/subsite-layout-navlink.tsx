import { Nav } from "react-bootstrap";
import { Link } from "react-router-dom";

type SubsiteLayoutNavLinkProps = {
  basepath: string;
  route: string;
  activeTab: string;
  children: React.ReactNode;
}

const SubsiteLayoutNavLink = ({basepath, route, activeTab, children}: SubsiteLayoutNavLinkProps) => {
  const fullRoute = `${basepath}${route}`
  const isActive = `/admin${fullRoute}` === activeTab;

  return (
    <Nav.Item>
      <Nav.Link 
        as={Link} 
        relative="path" 
        prefetch="intent"
        to={fullRoute} 
        active={isActive} 
        aria-current={isActive}
        className={`text-${isActive ? 'dark' : 'secondary'}`}
        style= {{ color: isActive ? 'black' : 'grey', }}
      >
        {children}
      </Nav.Link>
    </Nav.Item>
  )
}

export default SubsiteLayoutNavLink;