import { ReactNode } from "react";
import { useSiteSuspense } from "../api/get-site";
import { Container, Stack } from "react-bootstrap";
import AboutAccordion from "@/components/ui/about-accordion";


type EditSitePropertiesProps = {
  slug: string;
  children?: ReactNode;
}


const SiteProperties = ({ slug }: EditSitePropertiesProps): ReactNode => {
  const site = useSiteSuspense(slug);

  const aboutText = "about site properties"

  return (
    <Container>
      <Container>
        <h2>Edit Site Properties for <span className="text-info">{site.title}</span></h2>
      </Container>
      <Stack>
        <AboutAccordion header="About Site Properties" body={aboutText} />

      </Stack>
    </Container>
  )
}

export default SiteProperties;