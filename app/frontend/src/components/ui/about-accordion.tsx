import { ReactNode } from "react";
import { Accordion, Container } from "react-bootstrap";


type AboutAccordionPropsType = {
  header: string;
  body?: string;
  children?: ReactNode;
}
const AboutAccordion = ({ header, body, children }: AboutAccordionPropsType): ReactNode => {

  return (
    <Container fluid className="my-3">
      <Accordion >
        <Accordion.Item eventKey="0" >
          <Accordion.Header className="text-info fs-4">{header}</Accordion.Header>
          <Accordion.Body>{body ? body : children}</Accordion.Body>
        </Accordion.Item>
      </Accordion>
    </Container>
  )
}

export default AboutAccordion;