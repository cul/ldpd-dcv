import { Button } from "react-bootstrap";
import { useNavigate } from "react-router";

const BackButton = () => {
  const navigate = useNavigate();

  return (
    <Button variant="outline-info" className="fs-4 mt-4"
        onClick={() => navigate(-1)}
      >
        <i className="pe-3 fa-light fa-square-arrow-left"></i>
        Go Back
    </Button>
)}

export default BackButton;