import SiteDashboard from "@/features/subsite/components/site-dashboard";
import { useParams } from "react-router-dom";


const SiteDashboardRoute = () => {
  const { slug } = useParams();

  if (!slug) throw Error("No slug parameter provided");

  return (
    <SiteDashboard slug={slug} />
  )
}

export default SiteDashboardRoute;
