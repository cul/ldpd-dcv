import { Outlet } from "react-router-dom";
import SitesNavbar from "./sites-navbar";

const SitesLayout = () => {
  return (
    <div>
      <h2>Sites Layout</h2>
      <SitesNavbar />
      <Outlet />
    </div>
  );
};

export default SitesLayout;
