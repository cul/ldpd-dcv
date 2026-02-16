import { ReactNode } from "react";


const SiteEdit = ({ slug }: string) : ReactNode => {
  const { data: site, isLoading } = useSite(slug);

  return (
    <div>
      <h3>Editing Site: {site.title}</h3>
    </div>
  )
}

export default SiteEdit;