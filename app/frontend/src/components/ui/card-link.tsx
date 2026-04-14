import { ReactNode, useState } from "react";
import { useNavigate } from "react-router"
import { Col, Row } from "react-bootstrap"


type CardLinkProps = {
  to: string;
  label: string;
  faClass?: string;
}



const CardLink = ({ to, label, faClass }: CardLinkProps): ReactNode => {
  const navigate = useNavigate(); // Use use navigate to redirect user when they click on the card
  const [ hovering, setHovering ] = useState(false);

  const handleMouseEnter = () => { setHovering(true) };
  const handleMouseLeave = () => { setHovering(false) };
  const handleClick = () => {
    navigate(to);
  }

  return (
    <div
      onClick={handleClick}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      style={{ cursor: "pointer", transition: "background-color 0.3s ease" }}
      className={`m-2 m-lg-3 p-3 border border-3 border-info-subtle rounded ${hovering && 'bg-info-subtle'}`}
    >
      <Row className="text-secondary">
        <Col md={2} xs={12}>
          <i className={faClass} style={{ fontSize: 'clamp(2em, 4vw, 5em)' }}></i>
        </Col>
        <Col md={10} xs={12} className="p-2 ps-md-4 ps-5">
          {/* rightwards arrow: 8594 */}
          <h4>{String.fromCharCode(8680)} {label}</h4>
        </Col>
      </Row>
    </div>
  )
}

export default CardLink;