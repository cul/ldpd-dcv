import { Container, Stack } from "react-bootstrap";

const Footer = () => {

  return (
      <Container className="text-center py-4" >
        <Stack gap={3}>
          {/* LEVEL 1 */}
          <div className="fs-6 fw-light">
            You are in the administrator and editor section of the DLC website. Here you can manage subsites, configure their appearance, and more.
          </div>

          {/* LEVEL 2 */}
          <Container className="d-flex justify-content-around">
            <div><a href="/">Go back to the DLC Homepage</a></div>
            <div>
              {/* Give credit for icons: */}
              <a href="https://www.flaticon.com/free-icons/wrench" title="credit icons">Icons created by Dave Gandy - Flaticon</a>
            </div>
          </Container>
        </Stack>
      </Container>
  )
}

export default Footer;