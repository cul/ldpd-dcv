import { Button, Container } from "react-bootstrap";
import { FallbackProps } from "react-error-boundary";


export const MainErrorFallback = ({ error, resetErrorBoundary }: FallbackProps) => {
  
  return (
    <Container className="m-5">
      <h2>Oops, something went wrong</h2>
      <br />
      <p>The application encountered an error.</p>
      <Container>
        <pre>{String(error)}</pre>
      </Container>
      <Button onClick={resetErrorBoundary} >oop</Button>
    </Container>
  );
};