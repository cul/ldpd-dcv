import { useParams } from 'react-router';

import SubsiteDashboard from '@/features/subsite/components/subsite-dashboard';

const SiteDashboardRoute = () => {
  const { slug } = useParams();

  if (!slug) throw Error('No slug parameter provided');

  return <SubsiteDashboard slug={slug} />;
};

export default SiteDashboardRoute;
