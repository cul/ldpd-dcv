import SiteDashboard from "@/features/sites/components/site-dashboard";
import { useParams } from "react-router-dom";


const SiteDashboardRoute = () => {
  let { slug } = useParams();

  if (!slug) throw Error("No slug parameter provided");

  return (
    <SiteDashboard slug={slug} />
  )
}

export default SiteDashboardRoute;
