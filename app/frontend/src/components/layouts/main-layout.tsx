import { Outlet } from 'react-router';
import MainNavBar from '../main-navbar';

const MainLayout = () => {
  return (
    <>
      <header>
        <MainNavBar />
      </header>
      <div>
        <h1>Main Layout</h1>
        <Outlet />
      </div>
    </>
  );
};

export default MainLayout;