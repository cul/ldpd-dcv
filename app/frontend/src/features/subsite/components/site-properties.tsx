import { ReactNode } from "react";
import { Container, Stack } from "react-bootstrap";

import { useSiteSuspense } from "../api/get-site";
import AboutAccordion from "@/components/ui/about-accordion";
import GeneralPropertiesForm from "./site-properties/general-properties-form";
import HomepageImagesForms from "./site-properties/homepage-images-forms";
import FormAccordion from "@/components/ui/forms/form-accordion";
import SitePagesGeneralForm from "./site-properties/site-pages-general-form";


type EditSitePropertiesProps = {
  slug: string;
  children?: ReactNode;
}

const SiteProperties = ({ slug }: EditSitePropertiesProps): ReactNode => {
  const site = useSiteSuspense(slug);

  const aboutText = "about site properties"; // TODO : put real description


  return (
    <Container>
      <Container>
        <h2>Edit Site Properties for <span className="text-info">{site.title}</span></h2>
      </Container>

      <Stack>
        <AboutAccordion header="About Site Properties" body={aboutText} />

        <FormAccordion header="Edit Site General Properties">
            <GeneralPropertiesForm slug={slug} />

        </FormAccordion>

        <FormAccordion header="Edit Homepage Images" id="homepage-image-forms">
          <HomepageImagesForms slug={slug}/>
        </FormAccordion>

        <FormAccordion header="Manage Site Pages">
          <SitePagesGeneralForm slug={slug}/>

        </FormAccordion>

        {/* <FormAccordion header="Edit Homepage Images">
        </FormAccordion>

        <FormAccordion header="Edit Navigation Bar">
        </FormAccordion> */}
      </Stack>
    </Container>
  )
}

export default SiteProperties;