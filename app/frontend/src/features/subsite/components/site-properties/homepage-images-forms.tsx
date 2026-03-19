import { Accordion, Container } from "react-bootstrap";

import { useSiteSuspense } from "../../api/get-site";
import InfoTooltip from "@/components/ui/forms/info-tooltip";
import { sitePropertiesTooltipMessage } from "../../utils";
import PortraitLayoutImagesForm from './homepage-images-forms/portrait-layout-image-form';
import SignatureLayoutImagesForm from './homepage-images-forms/signature-layout-images-form';


// Renders the two homepage image forms -- one for portrait and one for signature layout
// If a subsite is not using either of those layout types, the forms will still be accessible
// but will be collapsed (and they will have no effect on the look of the subsite).
const HomepageImagesForms = ({slug}: {slug: string}) => {
  const site = useSiteSuspense(slug);

  return (
    <Container>
      <p>If you are using the <span className="fw-bold">Portrait</span> or <span className="fw-bold">Signature</span> Layout types, you can manage the images displayed on the site homepage here.</p>
      <Accordion defaultActiveKey={`${site.layout}-layout`}>
        <Accordion.Item eventKey="portrait-layout">
          <Accordion.Header><InfoTooltip fieldName="portraitLayoutImages" lookupFn={sitePropertiesTooltipMessage} />Portrait Layout Images</Accordion.Header>
          <Accordion.Body>
            <PortraitLayoutImagesForm slug={slug}/>
          </Accordion.Body>
        </Accordion.Item>
        <Accordion.Item eventKey="signature-layout">
          <Accordion.Header><InfoTooltip fieldName="signatureLayoutImages" lookupFn={sitePropertiesTooltipMessage} />Signature Layout Images</Accordion.Header>
          <Accordion.Body>
            <SignatureLayoutImagesForm slug={slug}/>
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>
    </Container>
  )
}

export default HomepageImagesForms;
