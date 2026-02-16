# Data Persistence Architecture for Site Configuration

## Overview

The application uses a sophisticated **custom ActiveRecord attribute type system** to persist complex nested configuration data for sites. Rather than creating separate database tables for each configuration entity, the data is stored as **serialized JSON** in a single `search_configuration` column on the `sites` table.

---

## How It Works: The Complete Flow

### 1. Database Storage

**Table:** `sites`  
**Column:** `search_configuration` (TEXT)

From [db/schema.rb](db/schema.rb):
```ruby
t.text "search_configuration"
```

The data is stored as a JSON string in this single TEXT column, NOT in separate tables.

---

### 2. Custom ActiveRecord Type System

Rails ActiveRecord supports custom attribute types that automatically serialize/deserialize data. This application registers two custom types:

**File:** [config/initializers/types.rb](config/initializers/types.rb)
```ruby
ActiveRecord::Type.register(:site_permissions, Site::Permissions::Type)
ActiveRecord::Type.register(:site_search_configuration, Site::SearchConfiguration::Type)
```

This registration makes the custom types available for use in model attributes.

---

### 3. Site Model Declaration

**File:** [app/models/site.rb](app/models/site.rb#L11)
```ruby
attribute :search_configuration, :site_search_configuration, default: -> {Site::SearchConfiguration.new}
```

This line tells Rails:
- The `:search_configuration` attribute uses the `:site_search_configuration` custom type
- If no value exists, create a new empty `Site::SearchConfiguration` object
- Rails will automatically call the type's serialization/deserialization logic

---

### 4. Custom Type Implementation

**File:** [app/models/site/search_configuration.rb](app/models/site/search_configuration.rb)

The `Site::SearchConfiguration` class defines a nested `Type` class:

```ruby
class Site::SearchConfiguration
  # ... attribute definitions ...
  
  class Type < ActiveModel::Type::Value
    include ActiveModel::Type::Helpers::Mutable

    def serialize(obj)
      # Called when SAVING to database
      JSON.dump(obj.as_json(compact: true))
    end

    def cast(src)
      # Called when LOADING from database
      case src
      when Site::SearchConfiguration
        src
      when Hash
        Site::SearchConfiguration.new(src)
      when Proc
        cast_value(src.call)
      else
        Site::SearchConfiguration.new(JSON.load(src))
      end
    end
  end
end
```

**Flow:**
- **`cast()` method** - Called when reading from database or assigning a value
  - Converts JSON string → `Hash` → `Site::SearchConfiguration` object
  
- **`serialize()` method** - Called when saving to database
  - Converts `Site::SearchConfiguration` object → Ruby Hash → JSON string

---

## Data Persistence Example

### Scenario: Changing Default Search Mode from "grid" to "list"

**Step 1: User submits form with new value**

The SearchConfigurationController's `update` action receives:
```ruby
{
  site: {
    search_configuration: {
      display_options: {
        default_search_mode: 'list'  # Changed from 'grid'
      }
    }
  }
}
```

**Step 2: Controller assigns nested attributes**

From [app/controllers/sites/search_configuration_controller.rb](app/controllers/sites/search_configuration_controller.rb):
```ruby
def update
  update_attributes = search_configuration_params
  @subsite.search_configuration.assign_attributes(update_attributes)
  @subsite.save!  # <-- This triggers serialization
end
```

**Step 3: The nested object hierarchy**

When `assign_attributes` is called:
1. The `search_configuration` object receives the new attributes
2. The `display_options` setter is called:
   ```ruby
   def display_options=(val)
     @display_options = val.is_a?(Site::DisplayOptions) ? val : Site::DisplayOptions.new(val)
   end
   ```
3. A new `Site::DisplayOptions` object is created from the params hash
4. The `display_options.default_search_mode=` setter validates and sets the value:
   ```ruby
   def default_search_mode=(val)
     @default_search_mode = VALID_SEARCH_MODES.include?(val) ? val : 'grid'
   end
   ```

**Step 4: Save to database**

When `@subsite.save!` is called:
1. Rails detects the `search_configuration` attribute has changed
2. Rails calls `Site::SearchConfiguration::Type.serialize()` which:
   - Calls `@search_configuration.as_json(compact: true)`
   - Returns a nested Hash structure
   - Converts to JSON string: 
     ```json
     {
       "display_options": {
         "default_search_mode": "list",
         "show_csv_results": false,
         ...
       },
       "date_search_configuration": {...},
       "facets": [...],
       "map_configuration": {...},
       "search_fields": [...]
     }
     ```
   - Stores in database as TEXT

**Step 5: Loading from database**

When a site is loaded from the database:
1. Rails calls `Site::SearchConfiguration::Type.cast()` with the JSON string
2. The JSON is parsed back into a Hash
3. A new `Site::SearchConfiguration` object is created from the Hash
4. All nested objects are recursively instantiated

---

## Nested Configuration Objects

The data structure is hierarchical with multiple nested object types:

### Site::SearchConfiguration (Top level)
**File:** [app/models/site/search_configuration.rb](app/models/site/search_configuration.rb)

Contains:
- `date_search_configuration` → `Site::DateSearchConfiguration`
- `display_options` → `Site::DisplayOptions`
- `facets` → Array of `Site::FacetConfiguration`
- `map_configuration` → `Site::MapConfiguration`
- `search_fields` → Array of `Site::SearchFieldConfiguration`

### Site::DisplayOptions
**File:** [app/models/site/display_options.rb](app/models/site/display_options.rb)

Attributes:
- `default_search_mode` (grid or list)
- `show_csv_results` (boolean)
- `show_original_file_download` (boolean)
- `show_other_sources` (boolean)
- `grid_field_types` (array of format, name, project)

### Site::DateSearchConfiguration
**File:** [app/models/site/date_search_configuration.rb](app/models/site/date_search_configuration.rb)

Attributes:
- `enabled` (boolean)
- `granularity_search` (string)
- `show_sidebar` (boolean)
- `show_timeline` (boolean)
- `sidebar_label` (string)

### Site::MapConfiguration
**File:** [app/models/site/map_configuration.rb](app/models/site/map_configuration.rb)

Attributes:
- `default_lat`, `default_long` (coordinates)
- `enabled` (boolean)
- `granularity_data`, `granularity_search`
- `show_items`, `show_sidebar` (booleans)

### Site::FacetConfiguration, Site::SearchFieldConfiguration
Additional nested object types for search facets and search fields.

---

## Why This Architecture?

This design has several advantages:

### 1. **Flexibility**
- Configuration structure can evolve without database migrations
- New nested properties can be added easily
- Each site can have different facet configurations

### 2. **Type Safety**
- Each configuration object includes `ActiveModel::Dirty` for change tracking
- Validation occurs in the object setters (e.g., `default_search_mode=`)
- Type coercion happens automatically

### 3. **Consistency**
- Single source of truth (the Site record)
- All configuration changes happen atomically with `site.save!`
- No separate configuration records to keep in sync

### 4. **Simplicity**
- No complex JOIN queries needed
- No foreign key relationships to manage
- Sites can be exported/imported as complete JSON documents

---

## How Data Flows Through the Update Form

**File:** [app/views/sites/search_configuration/edit.html.erb](app/views/sites/search_configuration/edit.html.erb)

The form binds to the nested structure:
```erb
<%= form_for @subsite, local: true, url: path, method: 'patch' do |f| %>
  <%= f.fields_for :search_configuration do |sc| %>
    <%= sc.fields_for :display_options do |do| %>
      <%= do.select :default_search_mode, ['grid', 'list'] %>
    <% end %>
  <% end %>
<% end %>
```

This generates parameters like:
```
site[search_configuration][display_options][default_search_mode]=list
```

The controller's `search_configuration_params` permit list specifies the nested structure:
```ruby
def search_configuration_params
  scp = params.require(:site)
    .require(:search_configuration).permit(
      display_options: [:default_search_mode, :show_csv_results, ...],
      date_search_configuration: [...],
      map_configuration: [...],
      facets: [...],
      search_fields: [...]
    )
end
```

---

## Similar Pattern: Site::Permissions

The same pattern is used for the `permissions` attribute:

**File:** [app/models/site.rb](app/models/site.rb#L12)
```ruby
attribute :permissions, :site_permissions, default: -> {Site::Permissions.new}
```

**File:** [app/models/site/permissions.rb](app/models/site/permissions.rb)

This stores permission configuration (remote_ids, remote_roles, locations) in a single JSON column.

---

## Database Reality

To see what's actually stored in the database:

```sql
SELECT slug, search_configuration FROM sites WHERE slug = 'my-site' LIMIT 1;
```

Returns something like:
```
slug: "my-site"
search_configuration: "{\"display_options\":{\"default_search_mode\":\"list\",\"show_csv_results\":false,...},\"date_search_configuration\":{...},...}"
```

---

## Summary

**The Key Insight:**
- There is NO separate `SearchConfigurations` table
- All configuration data is stored as a **JSON string** in the `sites.search_configuration` column
- Rails' **custom ActiveRecord types** automatically serialize/deserialize this data
- The configuration objects (`Site::SearchConfiguration`, `Site::DisplayOptions`, etc.) are **transient ActiveModel objects**, not ActiveRecord models
- They exist only in memory while being manipulated, then are converted to JSON for persistence

This is an elegant example of Rails' flexibility in handling complex nested data without requiring a proportional growth in database tables.
