import { ReactNode } from "react";
import { Accordion, Container } from "react-bootstrap";

type FormAccordionProps = {
  header: string;
  id?: string;
  open?: boolean;
  children: ReactNode;
}

// header: What will go in the header/clickable part of the accordion
// id?: optionally add an ID to the accordion body element--this allows us to create rules based on this ID to add custom styles to the accordion
// open?: by default, form accordions are expanded. Set this prop to false to have them render as collapsed.
// children: the form JSX element to render inside the accordion body
const FormAccordion = ({ header, id, open=true,  children }: FormAccordionProps): ReactNode => {

  return (
    <Container fluid className="my-3">
      <Accordion defaultActiveKey={open ? '0' : ''}>
        <Accordion.Item eventKey="0" >
          <Accordion.Header className="text-info fs-4">{header}</Accordion.Header>
          <Accordion.Body id={id}>
            {children}
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>
    </Container>
  )
}

export default FormAccordion;