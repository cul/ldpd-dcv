# Admin-Only Routes and Controller Actions Analysis

This document identifies all routes and controller actions that are restricted to admin users (or authenticated site editors) for the digital collections site management system.

## Authorization Model Overview

The application uses **CanCan** for authorization with an `Ability` model that defines permissions. There are two key permission levels:

1. **`:update` action on Site** - Can be performed by:
   - Users with `is_admin` flag set to true
   - Users whose `uid` is in the Site's `editor_uids` array
   
2. **`:admin` action on Site** - Can only be performed by:
   - Users with `is_admin` flag set to true (full admins only)

### Key Authorization Code
From [app/models/ability.rb](app/models/ability.rb):
```ruby
can :update, Site do |site|
  user&.is_admin || site.editor_uids.include?(user&.uid)
end
can :admin, Site do |site|
  user&.is_admin
end
```

### Authorization Enforcement
The authorization is enforced through the `authorize_site_update` method in [app/controllers/concerns/dcv/authenticated/access_control.rb](app/controllers/concerns/dcv/authenticated/access_control.rb):
```ruby
def authorize_site_update(site=@subsite)
  authorize_action_and_scope(:update, site)
end
```

This raises `CanCan::AccessDenied` if the user cannot update the site.

---

## Protected Routes and Actions

### 1. Site Management Routes

**Route Pattern:** `/sites/:slug/*`

**Controller:** [Sites::SitesController](app/controllers/sites_controller.rb)

| HTTP Method | Route | Action | Authorization | Description |
|-------------|-------|--------|---------------|-------------|
| GET | `/sites/:slug/edit` | `edit` | `:update` on Site | Display site edit form |
| PATCH/PUT | `/sites/:slug` | `update` | `:update` on Site | Update site properties (palette, layout, facets, search_type, nav_links, image_uris, etc.) |

**Before Action:** `authorize_site_update` (lines 18-19 of sites_controller.rb)

**Affected Site Properties (via `site_params`):**
- `palette` - Color palette selection
- `layout` - Layout template
- `show_facets` - Whether to show search facets
- `alternative_title` - Alternative site title
- `search_type` - Search interface type
- `editor_uids` - User IDs allowed to edit
- `image_uris` - Array of image URIs
- `nav_links_attributes` - Navigation links (nested)
  - `sort_group`, `sort_label`, `link`, `external`, `icon_class`
- `banner` - Banner image upload
- `watermark` - Watermark image upload

---

### 2. Site Pages Management Routes

**Route Pattern:** `/:slug/pages/*` and `/:slug/pages/:page_slug/edit`

**Controller:** [Sites::PagesController](app/controllers/sites/pages_controller.rb)

| HTTP Method | Route | Action | Authorization | Description |
|-------------|-------|--------|---------------|-------------|
| GET | `/:slug/pages/new` | `new` | `:update` on Site | Display new page form |
| POST | `/:slug/pages` | `create` | `:update` on Site | Create new site page |
| GET | `/:slug/pages/:page_slug/edit` | `edit` | `:update` on Site | Display page edit form |
| PATCH/PUT | `/:slug/pages/:page_slug` | `update` | `:update` on Site | Update page (slug, title, columns, text blocks, images) |
| DELETE | `/:slug/pages/:page_slug` | `destroy` | `:update` on Site | Delete site page (except 'home') |

**Before Action:** `authorize_site_update` (line 12 of sites/pages_controller.rb) - applied to all actions except `:index` and `:show`

**Affected Page Properties (via `page_params`):**
- `slug` - Page URL slug
- `title` - Page title
- `use_multiple_columns` - Convert to columns (1 or 2)
- `site_page_images_attributes` - Hero/inset images with:
  - `image_identifier` (doi:, asset:, or lweb: prefixed)
  - `alt_text`, `caption`, `style`
- `site_text_blocks_attributes` - Text content blocks with:
  - `label`, `markdown`, nested images

**Special Behavior:**
- The 'home' page cannot be deleted (validated)
- Pages are deleted with cascade to their text blocks and images

---

### 3. Site Permissions Management Routes

**Route Pattern:** `/:slug/permissions*`

**Controller:** [Sites::PermissionsController](app/controllers/sites/permissions_controller.rb)

| HTTP Method | Route | Action | Authorization | Description |
|-------------|-------|--------|---------------|-------------|
| GET | `/:slug/permissions/edit` | `edit` | `:update` on Site | Display permissions edit form |
| GET | `/:slug/permissions` | `show` | `:update` on Site | Redirect to edit |
| PATCH/PUT | `/:slug/permissions` | `update` | `:update` on Site | Update site permissions and editor UIDs |

**Before Action:** `authorize_site_update` (line 6 of sites/permissions_controller.rb)

**Affected Permissions Properties (via `permissions_params`):**
- `permissions` object:
  - `remote_ids` - Array of user IDs for access
  - `remote_roles` - Array of roles for access
  - `locations` - Array of location URIs for access
- `editor_uids` - Array of user UIDs allowed to edit (only `:admin` users can modify this)

**Special Authorization:**
The `permissions_params` method includes role-based filtering (line 38-40):
```ruby
if can?(:admin, @subsite)
  atts['editor_uids']&.strip!
  atts['editor_uids'] = atts['editor_uids'].split(/[\s,]+/).sort
else
  atts['editor_uids'] = @subsite.editor_uids  # Non-admins cannot change editor_uids
end
```

---

### 4. Site Scope Filters Management Routes

**Route Pattern:** `/:slug/scope_filters*`

**Controller:** [Sites::ScopeFiltersController](app/controllers/sites/scope_filters_controller.rb)

| HTTP Method | Route | Action | Authorization | Description |
|-------------|-------|--------|---------------|-------------|
| GET | `/:slug/scope_filters/edit` | `edit` | `:update` on Site | Display scope filters edit form |
| GET | `/:slug/scope_filters` | `show` | `:update` on Site | Redirect to edit |
| PATCH/PUT | `/:slug/scope_filters` | `update` | `:update` on Site | Update search scope filters |

**Before Action:** `authorize_site_update` (line 6 of sites/scope_filters_controller.rb)

**Affected Scope Filter Properties (via `scope_filter_params`):**
- `scope_filters_attributes` - Array of filters with:
  - `filter_type` (publisher, project, project_key, collection, collection_key, repository_code)
  - `value` - The filter value

**Behavior:**
- All existing scope filters are destroyed and replaced with new ones
- Multiple filters can be applied to a single site

---

### 5. Site Search Configuration Management Routes

**Route Pattern:** `/:slug/search_configuration*`

**Controller:** [Sites::SearchConfigurationController](app/controllers/sites/search_configuration_controller.rb)

| HTTP Method | Route | Action | Authorization | Description |
|-------------|-------|--------|---------------|-------------|
| GET | `/:slug/search_configuration/edit` | `edit` | `:update` on Site | Display search configuration form |
| GET | `/:slug/search_configuration` | `show` | `:update` on Site | Redirect to edit |
| PATCH/PUT | `/:slug/search_configuration` | `update` | `:update` on Site | Update search interface configuration |

**Before Action:** `authorize_site_update` (line 6 of sites/search_configuration_controller.rb)

**Affected Search Configuration Properties (via `search_configuration_params`):**
- `date_search_configuration`:
  - `enabled`, `granularity_search`, `show_sidebar`, `show_timeline`, `sidebar_label`
- `map_configuration`:
  - `default_lat`, `default_long`, `enabled`, `granularity_data`, `granularity_search`, `show_items`, `show_sidebar`
- `display_options`:
  - `default_search_mode`, `show_csv_results`, `show_original_file_download`, `show_other_sources`, `grid_field_types`
- `facets` - Array of facet configurations with:
  - `facet_fields_form_value`, `label`, `limit`, `sort`, `value_transforms`
- `search_fields` - Array of search field configurations with:
  - `type`, `label`

---

## Admin-Only Routes (Full Admins Only)

### Admin Interface Entry Point

**Route:** `/admin`

**Controller:** [AdminController](app/controllers/admin_controller.rb)

| HTTP Method | Route | Action | Authorization | Description |
|-------------|-------|--------|---------------|-------------|
| GET | `/admin` | `index` | None (yet) | React UI entry point for admin interface |

**Note:** Currently this route has no authorization checks. The comment indicates it's an "entrypoint for react UI app". Authorization should be added when building out the React API endpoints.

---

## Route Constraint Exclusions

The routing configuration includes constraints to prevent conflicts:

**From config/routes.rb (lines 126, 146):**
The dynamic page slug routes exclude specific reserved slugs:
```ruby
get "#{subsite_key}/:slug" => "#{subsite_key}#page",
  constraints: lambda { |req| !['edit', 'pages', 'permissions', 'scope_filters', 'search_configuration'].include?(req.params[:slug]) }
```

This prevents slug values matching these reserved admin routes.

---

## Public (Unauthenticated) Routes

For contrast, here are the key public routes that do NOT require authorization:

| HTTP Method | Route | Action | Description |
|-------------|-------|--------|-------------|
| GET | `/sites` | `index` | List all sites (JSON endpoint) |
| GET | `/sites/:slug` | `home` | View site homepage |
| GET | `/sites/:slug/:page_slug` | `page` | View site page |
| GET | `/sites/:slug/pages` | `index` | List pages in a site (JSON) |
| GET | `/sites/:slug/search` | `show` | Search within a site |

---

## Restricted Site Routes

All the above routes are **also available under the `/restricted` namespace** for restricted sites:

**Route Pattern:** `/restricted/:slug/*` (mirrors public routes with authorization checks)

**Controllers:** Located in [app/controllers/restricted/](app/controllers/restricted/) directory

These follow the same authorization patterns as their public counterparts.

**Additional Authorization for Restricted Sites:**
- Must pass `authorize_document` check (validates access via IP, roles, remote IDs)
- See [Ability model](app/models/ability.rb) `ACCESS_SUBSITE` permission logic

---

## Summary of Admin-Protected Actions

### Requiring `:update` Permission (Admin or Editor)
1. **Sites Controller**
   - `edit` - Display site edit form
   - `update` - Update site settings, layout, navigation

2. **Pages Controller**
   - `new` - Create new page form
   - `create` - Create new page
   - `edit` - Edit page form
   - `update` - Update page content and structure
   - `destroy` - Delete page

3. **Permissions Controller**
   - `edit` - Edit permissions form
   - `update` - Update permissions and editor UIDs

4. **Scope Filters Controller**
   - `edit` - Edit scope filters form
   - `update` - Update scope filters

5. **Search Configuration Controller**
   - `edit` - Edit search configuration form
   - `update` - Update search configuration

### Requiring `:admin` Permission (Full Admins Only)
- Modifying `editor_uids` in Permissions controller (line 38-40)

### No Current Authorization (To Be Protected)
- `/admin` route (React UI entry point)
- Any API endpoints created for the React frontend

---

## API Design Recommendations for React Frontend

When building the React admin interface API, consider:

1. **Protect all CRUD endpoints** with `:update` or `:admin` authorization as appropriate

2. **API Endpoints to Create:**
   - `GET /api/sites` - List all sites (admin only)
   - `GET /api/sites/:id` - Get site details (admin/editor only)
   - `POST /api/sites` - Create site (admin only)
   - `PATCH /api/sites/:id` - Update site (admin/editor)
   - `DELETE /api/sites/:id` - Delete site (admin only)
   - `GET /api/sites/:id/pages` - List pages (admin/editor)
   - `POST /api/sites/:id/pages` - Create page (admin/editor)
   - `PATCH /api/sites/:id/pages/:page_id` - Update page (admin/editor)
   - `DELETE /api/sites/:id/pages/:page_id` - Delete page (admin/editor)
   - And similar for permissions, scope_filters, search_configuration

3. **Authentication:** Ensure user is authenticated and belongs to the site's `editor_uids` or is an admin

4. **JSON Responses:** Return JSON instead of HTML redirects for API calls

5. **Error Handling:** Return appropriate HTTP status codes:
   - `401 Unauthorized` - Not authenticated
   - `403 Forbidden` - Authenticated but not authorized
   - `404 Not Found` - Resource not found
   - `422 Unprocessable Entity` - Validation errors

---

## Authorization Flow Diagram

```
User Request
    ↓
Authenticate (Devise/Omniauth)
    ↓
Check Route Authorization
    ↓
before_action :authorize_site_update
    ↓
Ability.can?(:update, site)
    ├─ Is user.is_admin? → ALLOW
    └─ Is user.uid in site.editor_uids? → ALLOW
    └─ Otherwise → DENY (CanCan::AccessDenied)
    ↓
Action Execution
    ↓
Render Response
```

---

## Current Implementation Notes

1. The application is a Rails MVC application with Blacklight integration
2. Admin interface currently uses ERB templates (referenced in routes as `edit` views)
3. Redirect logic redirects between public and restricted namespaces based on `restricted?` flag
4. Navigation links and site configuration support nested attributes for form convenience
5. File uploads (banner, watermark) are handled separately through CarrierWave
6. The Site model supports Blacklight customization per site

