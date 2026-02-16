# Database Schema and Active Record Relationships

This document describes the relational database structure and Active Record model relationships for the LDPD-DCV application.

## Database Overview

The application uses SQLite (development environment) with the following core tables representing site management, navigation, and user functionality for a Digital Collections viewer.

---

## Core Tables and Models

### Users Table
**Model:** `User`
**Purpose:** Manages user authentication, authorization, and profile information.

**Columns:**
- `id` (PK) - Primary key
- `first_name` - User's first name
- `last_name` - User's last name
- `is_admin` - Boolean flag indicating admin status
- `email` - User's email address (unique)
- `encrypted_password` - Encrypted password from Devise
- `reset_password_token` - Token for password reset
- `reset_password_sent_at` - Timestamp of password reset email
- `remember_created_at` - Timestamp for remember-me functionality
- `sign_in_count` - Number of times user has signed in
- `current_sign_in_at` - Timestamp of current sign-in
- `last_sign_in_at` - Timestamp of last sign-in
- `current_sign_in_ip` - IP address of current session
- `last_sign_in_ip` - IP address of last session
- `guest` - Boolean flag for guest users
- `provider` - OAuth provider (e.g., 'cas')
- `uid` - User ID from OAuth provider
- `created_at` - Record creation timestamp
- `updated_at` - Record last update timestamp

**Indexes:**
- `email` (unique)
- `provider`
- `uid`
- `reset_password_token` (unique)

**Relationships:**
- Used by Blacklight for user bookmarks and searches (polymorphic associations)
- Includes Devise modules for authentication
- Includes Omniauth modules for federated authentication

**Key Features:**
- Uses Devise for authentication
- Supports OAuth/Omniauth integration (CAS)
- Role-based access control via `role_symbols` and `role?` methods
- Can be admin users (`is_admin?` method)

---

### Sites Table
**Model:** `Site`
**Purpose:** Represents distinct digital collection sites or themed browsing interfaces.

**Columns:**
- `id` (PK) - Primary key
- `slug` - URL-friendly identifier (unique)
- `title` - Display title for the site
- `persistent_url` - External persistent URL for the site
- `publisher_uri` - URI identifying the publisher
- `image_uris` - Serialized array of image URIs
- `repository_id` - Reference to the repository
- `layout` - Layout template choice (validated against `VALID_LAYOUTS`)
- `palette` - Color palette identifier
- `search_type` - Type of search interface (validated against `VALID_SEARCH_TYPES`)
  - Possible values: `SEARCH_LOCAL`, `SEARCH_REPOSITORIES`, `SEARCH_CATALOG`
- `restricted` - Boolean indicating if site is restricted
- `permissions` - Serialized permissions object (type: `Site::Permissions`)
- `map_search` - Configuration for map-based search
- `date_search` - Configuration for date-based search
- `alternative_title` - Alternative name for the site
- `show_facets` - Boolean to show/hide search facets (default: false)
- `editor_uids` - Serialized array of user UIDs who can edit
- `search_configuration` - Serialized search configuration object (type: `Site::SearchConfiguration`)
- `created_at` - Record creation timestamp
- `updated_at` - Record last update timestamp

**Indexes:**
- `slug` (unique)

**Relationships:**
- `has_many :nav_links` (dependent: :destroy) - Site navigation links
- `has_many :site_pages` (dependent: :destroy) - Site content pages
- `has_many :scope_filters` (as: :scopeable) - Polymorphic association for search scope filters
- `accepts_nested_attributes_for :nav_links` - Allow inline editing
- `accepts_nested_attributes_for :scope_filters` - Allow inline editing

**Custom Attributes:**
- `search_configuration` - Custom ActiveRecord attribute type (`site_search_configuration`)
- `permissions` - Custom ActiveRecord attribute type (`site_permissions`)

**Key Features:**
- Includes Blacklight configuration for customizable search interfaces
- Each site can have its own Blacklight search configuration
- Supports `SEARCH_LOCAL`, `SEARCH_REPOSITORIES`, and `SEARCH_CATALOG` search types
- Sites are deleted along with their dependent nav_links and site_pages (cascade delete)

---

### SitePages Table
**Model:** `SitePage`
**Purpose:** Represents content pages within a site (e.g., About page, Browse page).

**Columns:**
- `id` (PK) - Primary key
- `slug` - URL-friendly page identifier (unique per site)
- `title` - Display title for the page
- `columns` - Number of text columns (1 or 2, default: 1)
- `site_id` (FK) - Reference to parent Site
- `created_at` - Record creation timestamp
- `updated_at` - Record last update timestamp

**Indexes:**
- `[site_id, slug]` (unique) - Ensures slug uniqueness per site

**Relationships:**
- `belongs_to :site` (touch: true) - Parent site (updates site's updated_at when page changes)
- `has_many :site_text_blocks` (dependent: :destroy, inverse_of: :site_page) - Content text blocks
- `has_many :site_page_images` (dependent: :destroy, as: :depictable) - Polymorphic images
- `accepts_nested_attributes_for :site_text_blocks` (allow_destroy: true) - Inline editing
- `accepts_nested_attributes_for :site_page_images` (allow_destroy: true) - Inline editing

**Validations:**
- `columns` must be between 1 and 2
- `slug` must be unique per site
- `home` slug cannot be modified (validated by `home_slug_does_not_change`)
- `site_page_images` are validated

**Key Features:**
- Auto-generates title from slug (titlecase conversion) if not provided
- Supports 1-2 column layouts
- `has_columns?` checks if multi-column layout is used
- `text_block_columns` method partitions content into two columns if needed
- Pages are deleted along with their text blocks and images (cascade delete)

---

### SiteTextBlocks Table
**Model:** `SiteTextBlock`
**Purpose:** Represents individual text content blocks on a site page.

**Columns:**
- `id` (PK) - Primary key
- `sort_label` - Sort order and label (format: "02:Block Title")
- `markdown` - Markdown content for the block
- `site_page_id` (FK) - Reference to parent SitePage
- `created_at` - Record creation timestamp (implicit)
- `updated_at` - Record last update timestamp (implicit)

**Relationships:**
- `belongs_to :site_page` (touch: true) - Parent page (updates page's updated_at)
- `has_many :site_page_images` (dependent: :destroy, as: :depictable) - Polymorphic images
- `accepts_nested_attributes_for :site_page_images` (allow_destroy: true) - Inline editing

**Key Features:**
- `label` method extracts the label part from `sort_label` (e.g., "02:Block Title" → "Block Title")
- `export_filename_for_sort_label` converts sort_label to a filename format
- `sort_label_from_filename` converts filename back to sort_label format
- Supports markdown content rendering
- Text blocks are deleted along with their images (cascade delete)

---

### SitePageImages Table
**Model:** `SitePageImage`
**Purpose:** Represents images associated with site pages or text blocks (polymorphic).

**Columns:**
- `id` (PK) - Primary key
- `image_identifier` - Identifier for the image (format: "doi:", "asset:", or "lweb:" prefix required)
- `style` - Display style ("hero" or "inset", default: "hero")
- `depictable_type` - Polymorphic type (e.g., "SitePage", "SiteTextBlock")
- `depictable_id` - Polymorphic ID of the associated object
- `alt_text` - Alternative text for accessibility
- `caption` - Image caption text
- `created_at` - Record creation timestamp (implicit)
- `updated_at` - Record last update timestamp (implicit)

**Indexes:**
- `[depictable_type, depictable_id]` - For polymorphic association query optimization

**Relationships:**
- `belongs_to :depictable` (polymorphic: true, touch: true) - Associated content object
  - Can be associated with: `SitePage` or `SiteTextBlock`
- Images are deleted when their parent objects are deleted (cascade)

**Validations:**
- `style` must be "hero" or "inset"
- `image_identifier` must start with "doi:", "asset:", or "lweb:" prefix
- `caption` is required for non-DOI images

**Key Features:**
- Polymorphic association allows reuse for both page and text block images
- Validates caption requirements (DOI images don't require captions)
- Touch parent on updates to maintain cache invalidation

---

### NavLinks Table
**Model:** `NavLink`
**Purpose:** Represents navigation menu links within a site.

**Columns:**
- `id` (PK) - Primary key
- `sort_label` - Sort order and link label (format: "02:Link Label")
- `sort_group` - Grouping identifier for navigation sections
- `link` - Target URL or page slug
- `external` - Boolean indicating if link is external
- `site_id` (FK) - Reference to parent Site
- `icon_class` - CSS class for icon display
- `created_at` - Record creation timestamp
- `updated_at` - Record last update timestamp

**Relationships:**
- `belongs_to :site` (touch: true) - Parent site (foreign key: site_id)
- NavLinks are deleted when parent site is deleted (cascade delete)

**Validations:**
- `sort_label` must be present
- `link` must be present

**Key Features:**
- `label` method extracts label from `sort_label` (e.g., "02:About" → "About")
- `about_link?` method identifies internal About page links (external=false, link="about")
- Links are deleted along with parent site (cascade delete)

**Foreign Key:**
- `sites` table via `site_id`

---

### ScopeFilters Table
**Model:** `ScopeFilter`
**Purpose:** Represents search scope filters (e.g., by publisher, project, collection) applied polymorphically to sites.

**Columns:**
- `id` (PK) - Primary key
- `filter_type` - Type of filter (validated values: publisher, project, project_key, collection, collection_key, repository_code)
- `value` - The value/identifier for the filter
- `scopeable_type` - Polymorphic type of the associated object (e.g., "Site")
- `scopeable_id` - Polymorphic ID of the associated object
- `created_at` - Record creation timestamp
- `updated_at` - Record last update timestamp

**Relationships:**
- `belongs_to :scopeable` (polymorphic: true, touch: true) - Associated object (e.g., Site)
  - Can be associated with: `Site` (and potentially other types)

**Validations:**
- `filter_type` must be one of: publisher, project, project_key, collection, collection_key, repository_code

**Key Features:**
- `FIELDS_FOR_FILTER_TYPES` constant maps filter types to Solr field names:
  - 'publisher' → 'publisher_ssim'
  - 'project' → 'lib_project_short_ssim'
  - 'project_key' → 'project_key_ssim'
  - 'collection' → 'lib_collection_sim'
  - 'collection_key' → 'collection_key_ssim'
  - 'repository_code' → 'lib_repo_code_ssim'
- `solr_field` method returns the Solr field name for the filter type
- Polymorphic association allows filters to be applied to multiple entity types

---

### Bookmarks Table
**Model:** `Bookmark` (from Blacklight gem)
**Purpose:** Stores user bookmarks for search results or documents.

**Columns:**
- `id` (PK) - Primary key
- `user_id` - Reference to user
- `user_type` - Type of user (e.g., "User")
- `document_id` - ID of the bookmarked document
- `document_type` - Type of document (e.g., "SolrDocument")
- `title` - User-provided title for the bookmark
- `created_at` - Record creation timestamp
- `updated_at` - Record last update timestamp

**Indexes:**
- `user_id`

**Purpose:** 
- Allows users to save and retrieve bookmarks of documents they find interesting
- Part of the Blacklight gem's core functionality

---

### Searches Table
**Model:** `Search` (from Blacklight gem)
**Purpose:** Stores user search queries for history and saved searches.

**Columns:**
- `id` (PK) - Primary key
- `query_params` - Serialized search parameters
- `user_id` - Reference to user
- `user_type` - Type of user (e.g., "User")
- `created_at` - Record creation timestamp
- `updated_at` - Record last update timestamp

**Indexes:**
- `user_id`

**Purpose:**
- Maintains search history for users
- Part of the Blacklight gem's core functionality

---

### NyreProjects Table
**Model:** `Nyre::Project`
**Purpose:** Represents New York Review projects (a specific project namespace).

**Columns:**
- `id` (PK) - Primary key
- `call_number` - Project call number
- `name` - Project name
- `created_at` - Record creation timestamp (implicit)
- `updated_at` - Record last update timestamp (implicit)

**Indexes:**
- `call_number`

**Model Details:**
- Uses `self.table_name_prefix = 'nyre_'` to use the "nyre_projects" table

**Validations:**
- `call_number` must be present

---

## Non-Database Models

### ArchivalContext
**Purpose:** Represents archival context information (JSON-backed, no database table).

A non-ActiveRecord class that represents hierarchical archival context from external data sources.

**Attributes:**
- `id` - Unique identifier
- `title` - Title of the context
- `bib_id` - Bibliographic ID
- `type` - Context type (e.g., "collection")
- `contexts` - Array of hierarchical contexts
- `repo_code` - Repository code
- `aspace_id` - ArchivesSpace ID

**Key Methods:**
- `catalog_url` - Generates CLIO catalog URL
- `finding_aid_url` - Generates finding aid URL with optional series/subseries
- `titles` - Generates hierarchical titles

---

### SolrDocument
**Purpose:** Represents documents indexed in Solr (read-only, no persistence).

Wraps Solr search results from Blacklight searches.

**Key Features:**
- `ACCESS_CONTROL_FIELDS` - Array of access control field names
- `TITLE_FIELDS` - Array of possible title field names
- Includes Blacklight extensions for Email and SMS
- Methods for checking if document is resource or site result
- `solr_url_hash` method for parsing location URLs

**Key Included Modules:**
- `Blacklight::Solr::Document`
- `SolrDocument::CleanResolver`
- `SolrDocument::FieldSemantics`
- `SolrDocument::PublicationInfo`
- `SolrDocument::Snippets`

---

### NavMenu
**Purpose:** Represents a navigation menu collection (non-persistent model).

An ActiveModel object that groups navigation links.

**Attributes:**
- `sort_label` - Menu group label with sort order
- `links` - Array of NavLink objects

**Key Methods:**
- `label` - Extracts label from sort_label
- `links_attributes=` - Setter for form integration

---

## Key Relationships Diagram

```
User
├── has_many: bookmarks (polymorphic)
└── has_many: searches

Site
├── has_many: nav_links (dependent: destroy)
├── has_many: site_pages (dependent: destroy)
└── has_many: scope_filters (polymorphic, dependent: destroy)

SitePage
├── belongs_to: site (touch: true)
├── has_many: site_text_blocks (dependent: destroy)
└── has_many: site_page_images (polymorphic, dependent: destroy)

SiteTextBlock
├── belongs_to: site_page (touch: true)
└── has_many: site_page_images (polymorphic, dependent: destroy)

SitePageImage (Polymorphic)
├── belongs_to: depictable (polymorphic - SitePage or SiteTextBlock)

NavLink
└── belongs_to: site (touch: true)

ScopeFilter (Polymorphic)
└── belongs_to: scopeable (polymorphic - typically Site)

Nyre::Project
└── (independent table)
```

---

## Foreign Keys

The application explicitly defines the following foreign key constraints:

1. `nav_links.site_id` → `sites.id`
2. `site_pages.site_id` → `sites.id`
3. `site_text_blocks.site_page_id` → `site_pages.id`

Polymorphic foreign keys use the `*_type` and `*_id` column pattern:
- `site_page_images` uses `depictable_type` and `depictable_id`
- `scope_filters` uses `scopeable_type` and `scopeable_id`
- Bookmarks use `user_type`, `user_id`, `document_type`, `document_id`

---

## Notable Design Patterns

### 1. **Polymorphic Associations**
   - `SitePageImage` can be associated with both `SitePage` and `SiteTextBlock`
   - `ScopeFilter` can be associated with `Site` (and potentially other entities)
   - Used for flexibility and reusability

### 2. **Cascade Delete**
   - Deleting a Site cascades to delete all NavLinks and SitePages
   - Deleting a SitePage cascades to delete all SiteTextBlocks
   - Deleting any entity cascades to delete associated SitePageImages
   - Maintains referential integrity automatically

### 3. **Touch: true**
   - Used on all `belongs_to` relationships to update parent timestamps
   - Enables effective caching and change tracking

### 4. **Custom Serialized Attributes**
   - `Site#permissions` - Uses `site_permissions` ActiveRecord type
   - `Site#search_configuration` - Uses `site_search_configuration` ActiveRecord type
   - `Site#editor_uids` - Serialized as Array
   - `Site#image_uris` - Serialized as Array
   - Allows complex object storage in simple columns

### 5. **Nested Attributes**
   - Sites accept nested NavLink and ScopeFilter attributes for form editing
   - SitePages accept nested SiteTextBlock and SitePageImage attributes
   - SiteTextBlocks accept nested SitePageImage attributes
   - Enables single-form editing of hierarchical data

### 6. **Blacklight Integration**
   - Site inherits Blacklight::Configurable for search customization
   - User includes Blacklight::User for bookmark/search persistence
   - SolrDocument wraps Solr results with semantic field mappings

### 7. **Authentication & Authorization**
   - User model includes Devise for authentication
   - Omniauth integration for federated auth (CAS)
   - Role-based access control via role_symbols and role? methods

---

## Database Constraints and Validations

### Uniqueness Constraints
- `User#email` - Unique across all users
- `Site#slug` - Unique across all sites
- `SitePage#[site_id, slug]` - Slug unique per site
- `User#reset_password_token` - Unique token per password reset

### Data Type Constraints
- `SitePageImage#style` - Must be "hero" or "inset"
- `SitePageImage#image_identifier` - Must start with "doi:", "asset:", or "lweb:"
- `SitePage#columns` - Must be 1 or 2
- `Site#search_type` - Must be in VALID_SEARCH_TYPES
- `Site#layout` - Must be in VALID_LAYOUTS
- `ScopeFilter#filter_type` - Must be in VALID_TYPES

### Business Logic Constraints
- `SitePage#home` slug cannot be changed after creation
- `SitePageImage` requires caption for non-DOI images
- `NavLink` requires sort_label and link

---

## Summary

This application implements a sophisticated digital collections discovery platform with:
- **User management** via Devise and Omniauth
- **Multi-site architecture** supporting different search interfaces and configurations
- **Rich content management** with pages, text blocks, and images
- **Flexible navigation** with sortable, groupable links
- **Advanced search** with polymorphic scope filters and Blacklight integration
- **Bookmark/search persistence** for user engagement
- **Cascade delete safety** ensuring referential integrity

The schema emphasizes flexibility through polymorphic associations while maintaining referential integrity through cascade deletes and foreign keys.
