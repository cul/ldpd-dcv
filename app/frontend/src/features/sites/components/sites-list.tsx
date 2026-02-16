import { ReactNode } from "react";

import { Site } from "@/types/api";
import { UseSites } from "../api/get-sites";


const SitesList = (): ReactNode => {
  console.log('siteslist')
  const { data: sites, isLoading } = UseSites();

  if (isLoading) {
    return <div>Loading sites...</div>
  }

  if (!sites) {
    return <div>no sites?</div>
  }

  return (
    <div>
      <ul>
        {sites.map((site) => (
          <li key={site.id}>{site.title}</li>
        ))}
      </ul>
    </div>
  )};

export default SitesList;