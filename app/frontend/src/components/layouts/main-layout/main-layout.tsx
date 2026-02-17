import { Outlet } from 'react-router-dom';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

import AuthenticationBoundary from "@/components/auth/authentication-boundary";
import MainNavBar from "./main-navbar";
import Footer from "./footer";


const MainLayout = () => {
  return (
    <AuthenticationBoundary>
      <div className="d-flex flex-column" style={{ minHeight: "100vh", }}>
        {import.meta.env.DEV && <ReactQueryDevtools />}
        <header className="flex-grow-0 flex-shrink-0">
          <MainNavBar />
        </header>
        <div className="container my-4 flex-grow-1">
          <Outlet />
        </div>
        <footer  className="flex-grow-0 flex-shrink-0 bg-dark-subtle">
          <Footer />
        </footer>
      </div>

    </AuthenticationBoundary>
  );
};

export default MainLayout;