import { ReactNode, Suspense } from "react";
import { Spinner, Stack } from "react-bootstrap";


type FetchingSuspenseProps = {
  dataName?: string;
  children?: ReactNode;
}

const FetchingSuspense = ({ dataName, children}: FetchingSuspenseProps): ReactNode => {
  return (
    <Suspense fallback={
      <Stack gap={5} className="m-5 justify-content-center align-items-center">
        <Spinner variant="info" style={{ width: "7em", height: "7em" }} role="status">
          <span className="visually-hidden">Loading {dataName ?? 'data'}...</span>
        </Spinner>
        <span className="fs-4">Loading {dataName ?? 'data'}...</span>
      </Stack>
        }
      >
        {children}
    </Suspense>
)};

export default FetchingSuspense;