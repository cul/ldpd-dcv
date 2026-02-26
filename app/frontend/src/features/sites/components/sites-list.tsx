import { ReactNode } from "react";

import { useSitesSuspense } from "../api/get-sites";
import { Link } from "react-router-dom";
import { Col, Container, Row } from "react-bootstrap";
import { useQueryClient } from "@tanstack/react-query";
import { getSiteQueryOptions } from "@/features/subsite/api/get-site";


const SitesList = (): ReactNode => {
  const sites = useSitesSuspense();
  const queryClient = useQueryClient();
  const handleMouseEnter = (slug: string) => {
    console.log(`            ON MOUSE ENTER! : PREFETCHING : /${slug}`);
    queryClient.prefetchQuery(getSiteQueryOptions(slug));
  }

  return (
    <Container fluid>
      <Row>
        <Col>Site Name</Col>
        <Col>Site Slug</Col>
        <Col></Col>
      </Row>
      {sites.map((site) => (
        <Row key={site.id}>
          <Col>{site.title}</Col>
          <Col>{site.slug}</Col>
          <Col><Link to={site.slug} onMouseEnter={() => handleMouseEnter(site.slug)}>Edit this site</Link></Col>
        </Row>
      ))}
    </Container>
  )
}

export default SitesList;