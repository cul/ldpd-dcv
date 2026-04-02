import { useParams } from "react-router";

import SiteDashboard from "@/features/subsite/components/site-dashboard";


const SiteDashboardRoute = () => {
  const { slug } = useParams();

  if (!slug) throw Error("No slug parameter provided");

  return (
    <SiteDashboard slug={slug} />
  )
}

export default SiteDashboardRoute;
