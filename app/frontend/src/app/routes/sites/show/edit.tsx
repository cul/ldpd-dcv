import { useParams } from "react-router-dom";

import EditSiteProperties from "@/features/sites/components/edit-site-properties";


const SitesEditRoute = () => {
  console.log("rendering sites edit route")
  let { slug } = useParams();

  if (!slug) throw Error("No slug parameter provided");

  return (
    <EditSiteProperties slug={slug} />
  )
}
export { SitesEditRoute as default };
