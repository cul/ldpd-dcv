import { useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router';

import { Container, Table } from 'react-bootstrap';
import { getSiteQueryOptions } from '@/features/subsite/api/get-site';
import { Site } from '@/types/api';

const SitesList = ({ sites }: { sites: Site[] }) => {
  const queryClient = useQueryClient();
  const handleMouseEnter = (slug: string) => {
    queryClient.prefetchQuery(getSiteQueryOptions(slug));
  };
  return (
    <Container className="mt-4">
      <h2 className="ps-4 mb-2">Your DLC Subsites</h2>
      <Table aria-label='Your DLC Subsites' striped hover style={{ '--bs-table-striped-bg': '#e8f9fc', '--bs-table-hover-bg': '#cff4fc' } as React.CSSProperties}>
        <thead>
          <tr>
            <th>
              Site Name
            </th>
            <th>
              Site Slug
            </th>
            <th>
              Link to Subsite Dashboard
            </th>
          </tr>
        </thead>
        <tbody>
          {sites.map((site, i) => (
            <tr className="my-4" key={i}>
              <td>
                <a href={`/${site.slug}`}>{site.title}</a>
              </td>
              <td>{site.slug}</td>
              <td>
                <Link to={site.slug} onMouseEnter={() => handleMouseEnter(site.slug)}>
                  <i className="pe-2 fa-duotone fa-solid fa-file-pen"></i>Edit this site
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
    </Container>
  );
};

export default SitesList;
