import { Link } from "react-router";

import { UseSites } from "@/features/sites/api/get-sites";

const SitesRoute = () => {
  // Component: sites/Index.tsx component!
};

//  todo: only admins
// const SitesRoute = () => {
//   // const access = authorizeUser();

//   const currentUser = useCurrentUser();

//   if (!currentUser.permissions.canEdit) { // enforces authorization
//     return <div>You do not have permission to view this page.</div>
//   }
//   if (currentUser.error) {
//     return <div>Error loading user account: {currentUser.error.message}</div>
//   }
// // await requireAuthorization(queryClient, [ROLES.ADMIN]);

//   const { data: sites, isLoading, error } = UseSites();

//   if (isLoading) {
//     return <div>Loading sites...</div>;
//   }

//   if (error) {
//     return <div>Error loading sites: {error.message}</div>;
//   }

//   return (
//     <div>
//       <h1>Sites</h1>
//       <p>This is the sites page. It will list all the sites for admins to edit.</p>
//       <div>
//         <div className='my-3'>
//           <Link to="/">&lt;&lt; Back to admin dashboard</Link>
//         </div>
//         <ul className="w-100">
//           {sites?.sites.map(site => (
//             <li className='row mb-4 border-bottom border-primary' key={site.slug}>
//               <div className='col-8'>
//                 <a href={`/${site.slug}`}>{site.title}</a>
//               </div>
//               <div className='col-1'>
//                 <a href={`/${site.slug}/edit`}>Edit</a>
//               </div>
//             </li>
//           ))}
//         </ul>
//       </div>
//     </div>
//   );
// };

export default SitesRoute;