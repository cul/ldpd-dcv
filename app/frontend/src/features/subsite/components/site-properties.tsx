import { ReactNode } from "react";
import { Container, Stack } from "react-bootstrap";

import { useSiteSuspense } from "../api/get-site";
import AboutAccordion from "@/components/ui/about-accordion";
import GeneralPropertiesForm from "./site-properties/general-properties-form";
import HomepageImagesForms from "./site-properties/homepage-images-forms";
import FormAccordion from "@/components/ui/forms/form-accordion";
import SitePagesGeneralForm from "./site-properties/site-pages-general-form";
import NavGroupsForm from "./site-properties/nav-groups-form";
import { SitePropertiesPageAboutText } from "@/components/ui/about-messages";


type EditSitePropertiesProps = {
  slug: string;
  children?: ReactNode;
}

const SiteProperties = ({ slug }: EditSitePropertiesProps): ReactNode => {
  const site = useSiteSuspense(slug);

  return (
    //  TODO : try using Cols and Rows to resize the centered content...
    <Container fluid style={{ maxWidth: '80vw'}}>
      <Container>
        <h2>Edit Site Properties for <span className="text-info">{site.title}</span></h2>
      </Container>

      <Stack>
        <AboutAccordion header="About Site Properties">
            <SitePropertiesPageAboutText />
        </AboutAccordion>

        <FormAccordion header="Edit Site General Properties">
            <GeneralPropertiesForm slug={slug} />
        </FormAccordion>

        <FormAccordion header="Edit Homepage Images" id="homepage-image-forms">
          <HomepageImagesForms slug={slug} />
        </FormAccordion>

        <FormAccordion header="Manage Site Pages">
          <SitePagesGeneralForm slug={slug} />
        </FormAccordion>

        <FormAccordion header="Edit Navigation Bar">
          <NavGroupsForm slug={slug} updatedAt={site.updatedAt} />
        </FormAccordion>

      </Stack>
    </Container>
  )
}

export default SiteProperties;