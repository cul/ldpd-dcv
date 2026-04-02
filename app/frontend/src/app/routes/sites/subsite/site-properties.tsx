import { useParams } from "react-router";

import SiteProperties from "@/features/subsite/components/site-properties";


const SitesEditRoute = () => {
  const { slug } = useParams();

  if (!slug) throw Error("No slug parameter provided");

  return (
    <SiteProperties slug={slug} />
  )
}
export { SitesEditRoute as default };
