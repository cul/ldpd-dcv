import { ReactNode } from "react";

import { Site } from "@/types/api";
import { useSites } from "../api/get-sites";
import { Link } from "react-router-dom";
import TableBuilder from "@/components/ui/table-builder/table-builder";
import { columnDefs } from "../utils/sites-column-defs";
import { Col, Container, Row } from "react-bootstrap";


const SitesList = (): ReactNode => {
  console.log('siteslist')
  const { data: sites, isLoading } = useSites();

  if (isLoading) {
    return <div>Loading sites...</div>
  }

  if (!sites) {
    return <div>no sites?</div>
  }

  return (
    <Container fluid>
      <Row>
        <Col>Site Name</Col>
        <Col>Site Slug</Col>
        <Col></Col>
      </Row>
      {sites.map((site) => (
        <Row>
          <Col>{site.title}</Col>
          <Col>{site.slug}</Col>
          <Col><Link to={site.slug}>Edit this site</Link></Col>
        </Row>
      ))}
    </Container>
  )

  return (
    <div>
      <ul>
        {sites.map((site) => (
          <li key={site.id}>{site.title} -- <Link to={site.slug}>Edit</Link></li>
        ))}
      </ul>
    </div>
  )};

export default SitesList;