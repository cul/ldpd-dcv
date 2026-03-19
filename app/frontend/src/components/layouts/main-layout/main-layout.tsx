import { Outlet, useNavigation } from 'react-router-dom';
// import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

import AuthenticationBoundary from "@/components/auth/authentication-boundary";
import MainNavBar from "./main-navbar";
import Footer from "./footer";

import TopBarProgress from "react-topbar-progress-indicator";

TopBarProgress.config({
  barColors: {
    "0": "#ffffff",
    "0.5": "#0DCAF0",
    "1.0": "#ffffff",
  },
  shadowBlur: 0
});


const LoadingBar = () => {
  // const fetching = useIsFetching();
  // const mutating = useIsMutating();
  const navigation = useNavigation();

  if (navigation.state !== 'idle') {
    // return <div className="border border-primary">LOADING . . . </div>
    return <TopBarProgress />
  }
}

const MainLayout = () => {
  return (
    <AuthenticationBoundary>
      <div className="d-flex flex-column" style={{ minHeight: "100vh", }}>
        <LoadingBar />
        {/* {import.meta.env.DEV && <ReactQueryDevtools />} */ /* This allows dev tools to be flush with footer (and not require scrolling) */}
        <header className="flex-grow-0 flex-shrink-0">
          <MainNavBar />
        </header>
        <div className="container-lg my-4 flex-grow-1">

          {/* <FetchingSuspense> */}
            <Outlet />
          {/* </FetchingSuspense> */}

        </div>
        <footer  className="flex-grow-0 flex-shrink-0 bg-dark-subtle">
          <Footer />
        </footer>
      </div>
    </AuthenticationBoundary>
  );
};

export default MainLayout;