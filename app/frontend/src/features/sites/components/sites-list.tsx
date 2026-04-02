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
    queryClient.prefetchQuery(getSiteQueryOptions(slug));
  }

  return (
    <Container>
      <h1 className='ps-2 my-4'>All DLC Subsites</h1>
      <Row className="mb-3">
        <Col className="text-center fst-italic">Site Name</Col>
        <Col className="text-center fst-italic">Site Slug</Col>
        <Col></Col>
      </Row>
      {sites.map((site) => (
        <Row key={site.id}>
          <Col className="border-end"><a href={`/${site.slug}`}>{site.title}</a></Col>
          <Col>{site.slug}</Col>
          {/*  TODO : Use prefetch="intent" rather than a custom onMouseEnter handler */}
          <Col><Link to={site.slug} onMouseEnter={() => handleMouseEnter(site.slug)}><i className="pe-2 fa-duotone fa-solid fa-file-pen"></i>Edit this site</Link></Col>
        </Row>
      ))}
    </Container>
  )
}

export default SitesList;