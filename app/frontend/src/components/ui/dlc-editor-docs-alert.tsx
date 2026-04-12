import { RefAttributes } from "react";
import { Alert, AlertProps } from "react-bootstrap"
import { JSX } from "react/jsx-runtime";

const DLCEditorDocsAlert = (props: JSX.IntrinsicAttributes & AlertProps & RefAttributes<HTMLDivElement>) => {
  return (
    <Alert variant="primary" {...props}>
      For detailed information about editing subsites, please refer to the <a href="https://columbiauniversitylibraries.atlassian.net/wiki/spaces/DLC/pages/3113574/Site+Editors#Page-Properties">DLC Site Editor Documentation</a>.
    </Alert>
  )
}

export default DLCEditorDocsAlert;