import { ReactNode } from "react";
import { useSiteSuspense } from "../api/get-site";
import { Container } from "react-bootstrap";


type EditSitePropertiesProps = {
  slug: string;
  children?: ReactNode;
}


const EditSiteProperties = ({ slug }: EditSitePropertiesProps): ReactNode => {
  const site = useSiteSuspense(slug);

  return (
    <Container>
      <h2>Edit Site Properties for <span className="text-info">{site.title}</span></h2>
    </Container>
  )
}

export default EditSiteProperties;