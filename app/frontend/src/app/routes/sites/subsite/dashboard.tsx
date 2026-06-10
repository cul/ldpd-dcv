import { useParams } from 'react-router';

import SubSiteDashboard from '@/features/subsite/components/subsite-dashboard';

const SiteDashboardRoute = () => {
  const { slug } = useParams();

  if (!slug) throw Error('No slug parameter provided');

  return <SubSiteDashboard slug={slug} />;
};

export default SiteDashboardRoute;
