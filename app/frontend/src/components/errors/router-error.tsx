import { Container } from "react-bootstrap";
import { useRouteError, isRouteErrorResponse } from "react-router";


export const RouteErrorFallback = () => {
  const error = useRouteError();

  return (
    <Container className="m-5">
      <h2>Oops, something went wrong</h2>
      <br />
      <p>The application encountered an error.</p>
      <Container>
        <pre>{String(error)}</pre>
        {isRouteErrorResponse(error) && ( // route errors
          <Container>
            <p>{error.status} {error.statusText}</p>
            <pre>{JSON.stringify(error.data, null, 2)}</pre>
          </Container>
        )}
      </Container>
    </Container>
  );
};