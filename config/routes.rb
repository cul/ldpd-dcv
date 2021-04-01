require 'resque/server'

Dcv::Application.routes.draw do
  root :to => "catalog#home"

  devise_for :users, skip: [:sessions], controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
  }

  devise_scope :user do
    get 'sign_in', :to => 'users/sessions#new', :as => :new_user_session
    get 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end

  resources :sessions, controller: 'users/sessions'

  mount Resque::Server.new, at: "/resque"

  get '/browse/:action' => 'browse', as: :browse
  get '/explore' => 'welcome#home'
  get '/about' => 'pages#about', as: :about

  get '/catalog/random' => 'catalog#random'
  get '/catalog/get_random_item' => 'catalog#random', defaults: { per_page: 1 }
  get '/catalog/:id/mods' => 'catalog#mods', as: :item_mods
  get '/catalog/:id/citation/:type' => 'catalog#show_citation', as: :item_citation

  get '/data/flare' => 'catalog#get_pivot_facet_data', as: :flare_data


  # Carnegie subsite routes
  get 'carnegie/about' => 'carnegie#about', as: :carnegie_about
  get 'carnegie/faq' => 'carnegie#faq', as: :carnegie_faq
  get 'carnegie/centennial_exhibition' => 'carnegie#centennial_exhibition', as: :carnegie_centennial_exhibition
  get 'carnegie/map_search' => 'carnegie#map_search', as: :carnegie_map_search

  # Durst subsite routes
  get 'durst/map_search' => 'durst#map_search', as: :durst_map_search
  get 'durst/help' => 'durst#help', as: :durst_help
  get 'durst/favorites' => 'durst#favorites', as: :durst_favorites
  get 'durst/about_the_collection' => 'durst#about_the_collection', as: :durst_about_the_collection
  get 'durst/about_the_project' => 'durst#about_the_project', as: :durst_about_the_project
  get 'durst/acknowledgements' => 'durst#acknowledgements', as: :durst_acknowledgements
  get 'durst/old_york_library_collection_categories' => 'durst#old_york_library_collection_categories', as: :durst_old_york_library_collection_categories

  # IFP subsite routes
  get 'ifp/partner/:key' => 'ifp#partner', as: :ifp_partner
  get 'restricted/ifp/partner/:key' => 'restricted/ifp#partner', as: :restricted_ifp_partner
  get 'ifp/about/about_the_ifp' => 'ifp#about_the_ifp', as: :ifp_about_the_ifp
  get 'ifp/about/about_the_collection' => 'ifp#about_the_collection', as: :ifp_the_collection

  # LCAAJ subsite routes
  get 'lcaaj/about' => 'lcaaj#about', as: :lcaaj_about
  get 'lcaaj/map_search' => 'lcaaj#map_search', as: :lcaaj_map_search

  # NYRE subsite routes
  get 'nyre/about' => 'nyre#about', as: :nyre_about
  get 'nyre/about-collection' => 'nyre#aboutcollection', as: :nyre_aboutcollection
  get 'nyre/map_search' => 'nyre#map_search', as: :nyre_map_search
  get 'nyre/projects/:id' => 'nyre/projects#show', as: :nyre_project, constraints: { id: /(\d+)|([A-Z]{2,3}\.\d{3,4}\.[A-Z]+)/ }

  # Blacklight routing concerns
  concern :searchable, Blacklight::Routes::Searchable.new
  concern :exportable, Blacklight::Routes::Exportable.new

  # Subsite routing concerns
  concern :publishable, Dcv::Routes::Publication.new
  concern :legacy_findable, Dcv::Routes::LegacyIds.new
  concern :previewable, Dcv::Routes::Previews.new
  concern :tree_browsable, Dcv::Routes::NodeProxies.new
  concern :search_compatibility, Dcv::Routes::SearchCompatibility.new
  concern :synchronizable, Dcv::Routes::Synchronizer.new

  # Generic Site concerns
  concern :site_searchable, Dcv::Routes::SiteSearchable.new
  concern :site_showable, Dcv::Routes::SiteShowable.new

  subsite_concerns = [:publishable, :legacy_findable, :previewable, :tree_browsable, :search_compatibility, :synchronizable]

  repositories = %w(NNC-A NNC-EA NNC-RB NyNyCAP NyNyCBL NyNyCMA)

  repositories_constraint = lambda { |req| repositories.include?(req.params[:id]) || repositories.include?(req.params[:repository_id]) }
  resources :repositories, path: '', constraints: repositories_constraint, shallow: true, only: [:show] do
    get 'reading-room', as: 'reading_room', action: 'reading_room'
    scope module: :repositories do
      resource 'catalog', only: [:show], controller: 'catalog' do
        # concerns :searchable
        all_concerns = [:searchable] + subsite_concerns
        concerns *all_concerns
      end
      get 'catalog/:id' => 'catalog#show', as: 'catalog_show' 
    end
  end

  # Dynamic routes for catalog controller and all subsites
  # namespace configs must come first for routes to work
  subsite_keys = (SUBSITES['public'].keys - ['uri']).map(&:to_sym)
  subsite_keys.each do |subsite_key|
    subsite_config = SUBSITES['public'][subsite_key.to_s]
    next unless subsite_config
    if subsite_config['nested'].present?
      namespace subsite_key do
        nested_keys = subsite_config['nested'].keys.map(&:to_sym)
        nested_keys.each do |nested_key|
          resource nested_key, only: [:show], controller: nested_key do
            # concerns :searchable
            all_concerns = [:searchable] + subsite_concerns
            concerns *all_concerns
          end
          get "#{nested_key}/:id" => "#{nested_key}#show", as: "#{nested_key}_show", constraints: Dcv::Routes::LEGACY_ID_CONSTRAINT
          get "#{nested_key}/*id" => "#{nested_key}#show", as: "#{nested_key}_show_doi", constraints: Dcv::Routes::DOI_ID_CONSTRAINT
        end
      end
    end
    resource subsite_key, only: [:show], controller: subsite_key do
      # concerns :searchable
      all_concerns = [:searchable] + subsite_concerns
      concerns *all_concerns
    end
    get "#{subsite_key}/:id" => "#{subsite_key}#show", as: "#{subsite_key}_show", constraints: Dcv::Routes::LEGACY_ID_CONSTRAINT
    get "#{subsite_key}/*id" => "#{subsite_key}#show", as: "#{subsite_key}_show_doi", constraints: Dcv::Routes::DOI_ID_CONSTRAINT
    get "#{subsite_key}/:slug" => "#{subsite_key}#page", as: "#{subsite_key}_page", constraints: lambda { |req| !['edit', 'pages', 'permissions', 'scope_filters', 'search_configuration'].include?(req.params[:slug]) }
  end

  get '/restricted' => 'home#restricted', as: :restricted
  get '/restricted/projects', to: redirect('/restricted')

  SITE_SLUG_CONSTRAINT ||= lambda { |req| (['images', 'stylesheets', 'javascripts'] & [req.params[:site_slug], req.params[:site_slug]]).blank? }

  if SUBSITES['restricted'].present?
    namespace "restricted" do
      subsite_keys = (SUBSITES['restricted'].keys - ['uri']).map(&:to_sym)
      subsite_keys.each do |subsite_key|
        resource subsite_key, only: [:show], controller: subsite_key do
          # concerns :searchable
          all_concerns = [:searchable] + subsite_concerns
          concerns *all_concerns
        end
        get "#{subsite_key}/:id" => "#{subsite_key}#show", as: "#{subsite_key}_show", constraints: Dcv::Routes::LEGACY_ID_CONSTRAINT
        get "#{subsite_key}/*id" => "#{subsite_key}#show", as: "#{subsite_key}_show_doi", constraints: Dcv::Routes::DOI_ID_CONSTRAINT
        get "#{subsite_key}/:slug" => "#{subsite_key}#page", as: "#{subsite_key}_page", constraints: lambda { |req| !['edit', 'pages', 'permissions', 'scope_filters', 'search_configuration'].include?(req.params[:slug]) }
      end
      get "sites" => "sites#index"
      get '/:slug', controller: 'sites', action: 'home', as: 'site'
      resources 'sites', only: [:edit, :update], param: :slug, path: '', constraints: SITE_SLUG_CONSTRAINT do
        scope module: :sites do
          resource 'permissions', only: [:edit, :show, :update], controller: 'permissions'
          resource 'scope_filters', only: [:edit, :show, :update], controller: 'scope_filters'
          resource 'search_configuration', only: [:edit, :show, :update], controller: 'search_configuration'
          resource 'search', only: [:show], controller: 'search' do
            concerns :site_searchable
          end
          get 'map_search', controller: 'search'
          concerns :site_showable
          resources 'pages', except: [:index, :create, :new], param: :slug, path: '', constraints: lambda { |req| !['edit', 'pages'].include?(req.params[:slug]) }
          resources 'pages', only: [:index, :create, :new], param: :slug
        end
      end
      get "sites/:slug", to: redirect("/%{slug}")
    end
  end

# IIIF presentation routes
  namespace  :iiif do
    scope ':version', version: /[23]/, registrant: /10\.[^\/]+/, doi: /[^\/]+/,
      collection_registrant: /10\.[^\/]+/, collection_doi: /[^\/]+/,
      manifest_registrant: /10\.[^\/]+/, manifest_doi: /[^\/]+/,
      defaults: { version: 3 } do
      defaults format: 'json' do
        get '/presentation/:manifest_registrant/:manifest_doi', to: 'presentations#show', as: :presentation
        get '/presentation/:collection_registrant/:collection_doi/collection(/*proxy_path)', to: 'presentations#collection', as: :collection, constraints: { format: 'json' }
        get '/presentation/:collection_registrant/:collection_doi/manifest/:manifest_registrant/:manifest_doi', to: 'presentations#manifest', as: :collected_manifest, constraints: { format: 'json' }
        get '/presentation/:manifest_registrant/:manifest_doi/manifest', to: 'presentations#manifest', as: :manifest
        get '/presentation/:manifest_registrant/:manifest_doi/canvas/:registrant/:doi', to: 'presentations#canvas', as: :canvas
        get '/presentation/:manifest_registrant/:manifest_doi/annotation/:registrant/:doi/:id', to: 'presentations#annotation', as: :annotation
        get '/presentation/:manifest_registrant/:manifest_doi/annotationPage/:registrant/:doi', to: 'presentations#annotation', as: :annotation_page
      end
    end
  end

# Sites routes, placed after explicit subsite routing in priority
  get "sites" => "sites#index"
  get "sites/:slug", to: redirect("/%{slug}")
  get '/:slug', controller: 'sites', action: 'home', as: 'site'
  resources 'sites', only: [:edit, :update], param: :slug, path: '', constraints: SITE_SLUG_CONSTRAINT do
    scope module: :sites do
      resource 'permissions', only: [:edit, :show, :update], controller: 'permissions'
      resource 'scope_filters', only: [:edit, :show, :update], controller: 'scope_filters'
      resource 'search_configuration', only: [:edit, :show, :update], controller: 'search_configuration'
      resource 'search', only: [:show], controller: 'search' do
        concerns :site_searchable
      end
      get 'map_search', controller: 'search'
      concerns :site_showable
      resources 'pages', except: [:index, :create, :new], param: :slug, path: '', constraints: lambda { |req| !['edit', 'pages'].include?(req.params[:slug]) }
      resources 'pages', only: [:index, :create, :new], param: :slug
    end
  end

  mount Blacklight::Engine => '/'

  resources :children, path: 'catalog/:parent_id/children', only: [:index, :show]

  resources :bytestreams, path: '/catalog/:catalog_id/bytestreams' do
    get 'content' => 'bytestreams#content'
  end

  namespace :resolve do
    resources :catalog, only: [:show], constraints: { id: /[^\?]+/ } do
      resources :bytestreams, only: [:index, :show] do
        get 'content'=> 'bytestreams#content'
      end
    end
    resources :bytestreams, path: 'catalog/:catalog_id/bytestreams', only: [:index, :show], constraints: { slug: /(?!.*edit).*/ }
  end

  get ':layout/:id/details' => 'details#show', as: :details

  #get 'resolve/catalog/*catalog_id/bytestreams/:id/content(.:format)' => 'resolve/bytestreams#content',
  # as: :resolve_bytestream_content #,
   #constraints: { catalog_id: /[^\/]+/ }
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
