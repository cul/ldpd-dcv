import { ReactNode } from "react";
import { Accordion, Container } from "react-bootstrap";


const FormAccordion = ({ header, children }: { header: string, children: ReactNode }): ReactNode => {

  return (
    <Container fluid className="my-3">
      <Accordion >
        <Accordion.Item eventKey="0" >
          <Accordion.Header className="text-info fs-4">{header}</Accordion.Header>
          <Accordion.Body>
            {children}
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>
    </Container>
  )
}

export default FormAccordion;