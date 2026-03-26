import { useSiteSuspense } from "../../api/get-site";

const NavGroupsForm = ({slug}: {slug: string}) => {
  const subsite = useSiteSuspense(slug);

  return <></>
}

export default NavGroupsForm;