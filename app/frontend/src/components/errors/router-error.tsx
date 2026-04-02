import { AuthError } from "@/types/errors";
import { Container } from "react-bootstrap";
import { useRouteError, isRouteErrorResponse } from "react-router";


export const RouteErrorFallback = () => {
  const error = useRouteError();
  console.log(error)

  const isAuthError = error instanceof AuthError;

  return (
    <Container className="m-5">
      <h2>Oops, something went wrong</h2>
      <br />
      <p>The application encountered an error.</p>
      <Container>
        <pre>{String(error)}</pre>
        {isAuthError && (
          <div>
            {error.authMessage && <p>{error.authMessage}</p>}
            <p>If you would like to sign in with a different account, <a href='/sign_out'>click here to log out</a>.</p>

          </div>
        )}
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