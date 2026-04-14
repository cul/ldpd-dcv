import { Outlet, useNavigation } from 'react-router';
import { Container } from 'react-bootstrap';
import TopBarProgress from "react-topbar-progress-indicator";

import AuthenticationBoundary from "@/components/auth/authentication-boundary";
import MainNavBar from "./main-navbar";
import Footer from "./footer";
import FetchingSuspense from '@/components/ui/fetching-suspense';


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
    return <TopBarProgress />
  }
}

const MainLayout = () => {
  return (
    <FetchingSuspense>
      <AuthenticationBoundary>
        <div className="d-flex flex-column" style={{ minHeight: "100vh", }}>
          <LoadingBar />
          {/* {import.meta.env.DEV && <ReactQueryDevtools />} */ /* This allows dev tools to be flush with footer (and not require scrolling) */}
          <header className="flex-grow-0 flex-shrink-0">
            <MainNavBar />
          </header>
          <Container fluid className="flex-grow-1" id="main-layout-body">

            <Outlet />

          </Container>
          <footer  className="flex-grow-0 flex-shrink-0 bg-dark-subtle">
            <Footer />
          </footer>
        </div>
      </AuthenticationBoundary>
    </FetchingSuspense>
  );
};

export default MainLayout;