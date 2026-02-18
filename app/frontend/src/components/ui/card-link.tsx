import { ReactNode, useState } from "react";
import { useNavigate } from "react-router-dom"
import { Col, Image, Row } from "react-bootstrap"


type CardLinkProps = {
  to: string;
  label: string;
  image?: string;
  altTxt?: string;
}



const CardLink = ({ to, label, image, altTxt }: CardLinkProps): ReactNode => {
  const navigate = useNavigate(); // Use use navigate to redirect user when they click on the card
  const [ hovering, setHovering ] = useState(false);

  const handleMouseEnter = () => { setHovering(true) };
  const handleMouseLeave = () => { setHovering(false) };
  const handleClick = () => {
    console.log("Inside card -- handle click! to: " + to)
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
        <Col xs={2} className="me-3">
          <Image alt={altTxt} src={image} style={{ width: 80, }} />
        </Col>
        <Col>
        <div className="p-2">
          {/* rightwards arrow: 8594 */}
          <h4>{String.fromCharCode(8680)} {label}</h4>
        </div>
        </Col>
      </Row>
    </div>
  )
}

export default CardLink;