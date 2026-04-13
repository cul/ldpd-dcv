import { useQueryClient } from "@tanstack/react-query";
import { Link } from "react-router";

import { Col, Container, Row } from "react-bootstrap";
import { getSiteQueryOptions } from "@/features/subsite/api/get-site";


const SitesList = ({sites}: {sites: Site[]}) => {
  const queryClient = useQueryClient();
  const handleMouseEnter = (slug: string) => {
    queryClient.prefetchQuery(getSiteQueryOptions(slug));
  }
  return (
    <Container className="mt-4">
      <h1 className='ps-4 mb-5'>All DLC Subsites</h1>
      <Row className="mb-3 text-center border-bottom">
        <Col xs={5} className="fst-italic border-end">Site Name</Col>
        <Col xs={4} className="fst-italic text-center border-end">Site Slug</Col>
        <Col xs={3} className="fst-italic">Link to Subsite Dashboard</Col>
      </Row>
      {sites.map((site, i) => {
        console.log(site, i);
        return (
          <Row key={site.id} className={`my-2 p-2 ${i % 2 === 0 && "bg-info-subtle rounded"}`}>
            <Col xs={5} className="border-end text-center"><a href={`/${site.slug}`}>{site.title}</a></Col>
            <Col xs={4} className="border-end text-center">{site.slug}</Col>
            {/*  TODO : Use prefetch="intent" rather than a custom onMouseEnter handler */}
            <Col xs={3} className="ps-4 text-start"><Link to={site.slug} onMouseEnter={() => handleMouseEnter(site.slug)}><i className="pe-2 fa-duotone fa-solid fa-file-pen"></i>Edit this site</Link></Col>
          </Row>
        )
      })}
    </Container>
  )
}

export default SitesList;