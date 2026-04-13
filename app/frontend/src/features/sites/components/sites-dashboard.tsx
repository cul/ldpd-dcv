import { Container } from "react-bootstrap";

import { useCurrentUserSuspense } from "@/lib/authentication";
import DLCEditorDocsAlert from "@/components/ui/dlc-editor-docs-alert";
import { useSitesSuspense } from "../api/get-sites";
import { ROLES } from "@/lib/authorization";
import SitesList from "./sites-dashboard/sites-list.tsx";


const SitesDashboard = () => {
  const currentUser = useCurrentUserSuspense();
  const isEditor = currentUser.permissions.role === ROLES.EDITOR;
  const sites = useSitesSuspense({ isEditor });

  return (
    <Container className="mt-4">
      <div className="ps-4 mb-5">
        {currentUser.permissions.role === ROLES.ADMIN && (<>
          <h1 className='ps-4 mb-5'>DLC Subsites Admin Dashboard</h1>
          <p>Welcome, DLC Administrator! Here you can view all the subsites you are approved to edit</p></>
        )}
        {currentUser.permissions.role === ROLES.EDITOR && (<>
          <h1>DLC Subsites Editor Dashboard</h1>
          <p className="mt-4">Welcome, DLC Editor! Here you can see all the subsites you are approved to edit.</p></>
        )}
        <DLCEditorDocsAlert textOnly/>
      </div>
      <SitesList sites={sites} />
    </Container>
  );
}

export default SitesDashboard;