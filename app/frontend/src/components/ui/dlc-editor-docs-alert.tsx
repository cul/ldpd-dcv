import { Alert } from "react-bootstrap"
import { JSX } from "react/jsx-runtime";


type DLCEditorDocsAlertProps = {
  textOnly?: boolean;
} & React.HTMLAttributes<HTMLElement>;

const DLCEditorDocsAlert = ({ textOnly, ...props }: DLCEditorDocsAlertProps): JSX.Element => {
  const textJSX = (<>
      For detailed information about editing subsites, please refer to the <a href="https://columbiauniversitylibraries.atlassian.net/wiki/spaces/DLC/pages/3113574/Site+Editors#Page-Properties" target="_blank" rel="noreferrer">DLC Site Editor Documentation</a>.
    </>);
  if(textOnly) {
    return <p>{textJSX}</p>
  };
  return (
    <Alert variant="primary" {...props}>
      {textJSX}
    </Alert>
  )
}

export default DLCEditorDocsAlert;