import { OverlayTrigger, Tooltip, TooltipProps } from "react-bootstrap";


type InfoTooltipPropTypes = {
  fieldName: string;
  lookupFn: ( fieldName: string ) => string | undefined;
};

// A generic tooltip for displaying information about a form field
// fieldName: the name of the field we are describing
// lookupFn: a method that takes the fieldName as input and outputs the info string
//           we define these methods in util files
const InfoTooltip = ( { fieldName, lookupFn }: InfoTooltipPropTypes ) => {
  const renderTooltip = (props: TooltipProps) => (
    <Tooltip id={`form-tooltip-${fieldName}`} {...props}>
      {lookupFn(fieldName)}
    </Tooltip>
  )

  return (
    <OverlayTrigger
      placement='right'
      delay={{show: 250, hide: 400}}
      overlay={renderTooltip}
    >
      <i className="px-2 fa fa-info-circle" aria-hidden="true"></i>
    </OverlayTrigger>
  )
}

export default InfoTooltip;