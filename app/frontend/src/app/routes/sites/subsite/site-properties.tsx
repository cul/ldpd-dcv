import { useParams } from 'react-router';

import SubsiteProperties from '@/features/subsite/components/subsite-properties';

const SitesEditRoute = () => {
  const { slug } = useParams();

  if (!slug) throw Error('No slug parameter provided');

  return <SubsiteProperties slug={slug} />;
};
export { SitesEditRoute as default };
