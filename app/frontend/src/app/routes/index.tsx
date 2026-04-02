import { Container } from "react-bootstrap";
import { Link } from "react-router";

const clientLoader = () => {
  console.log('todo : authorization')
}

 const AdminIndexRoute = () => {
  return (
    <Container className="my-5">
      <h1>Welcome to the <span className="text-info">DLC Administrator Section</span></h1>
      <Container className="mt-4">
        <p>At the moment, this section is a work in progress.</p>
        <p>You can currently edit and configure general properties of DLC subsites via each site{"'"}s <em>Subsite Dashboard.</em></p>

        <p>To navigate to a subsite dashboard, select a site from the <Link to="/sites">Sites List</Link> page.</p>
      </Container>
      <Container>
        <Link className="" to="/sites"><h3><i className=" pe-2 fa-duotone fa-solid fa-arrow-right-long"></i>View All Sites</h3></Link>
      </Container>
      <Container className="mt-5 ps-5 text-secondary">
        <p>I have been mostly using the Jay subsite as reference. <Link to="/sites/jay/site-properties">Go directly to the Jay Subsite Site Properties Editor</Link></p>
      </Container>
    </Container>
)};

export { clientLoader, AdminIndexRoute as default }