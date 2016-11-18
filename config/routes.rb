require 'resque/server'

Dcv::Application.routes.draw do
  root :to => "home#index"

  devise_for :users, skip: [:sessions], controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
  }

  devise_scope :user do
    get 'sign_in', :to => 'users/sessions#new', :as => :new_user_session
    get 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end

  resources :sessions, controller: 'users/sessions'

  mount Resque::Server.new, at: "/resque"
  
  # Dynamic robots.txt file
  get '/robots.txt' => 'pages#robots'

  get '/browse/:action' => 'browse', as: :browse
  get '/explore' => 'welcome#home'
  get '/about' => 'pages#about', as: :about
  get '/terms_of_use' => redirect('http://library.columbia.edu/about/policies/copyright-online-collections.html'), as: :terms_of_use

  get '/catalog/get_random_item' => 'catalog#get_random_item'
  get '/catalog/:id/mods' => 'catalog#mods', as: :item_mods
  get '/catalog/:id/citation/:type' => 'catalog#citation', as: :item_citation

  get '/data/flare' => 'catalog#get_pivot_facet_data', as: :flare_data

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

  # Jay subsite routes
  get 'jay/about' => 'jay#about', as: :jay_about
  get 'jay/collection' => 'jay#collection', as: :jay_collection
  get 'jay/bibliography' => 'jay#bibliography', as: :jay_bibliography
  get 'jay/participating_institutions' => 'jay#participating_institutions', as: :jay_participating_institutions
  get 'jay/biography' => 'jay#biography', as: :jay_biography
  get 'jay/jay_constitution' => 'jay#jay_constitution', as: :jay_jay_constitution
  get 'jay/jayandny' => 'jay#jayandny', as: :jay_jayandny
  get 'jay/jaytreaty' => 'jay#jaytreaty', as: :jay_jaytreaty
  get 'jay/jayandfrance' => 'jay#jayandfrance', as: :jay_jayandfrance
  get 'jay/jayandslavery' => 'jay#jayandslavery', as: :jay_jayandslavery

  resources 'sites', only: [:index, :show], param: :slug
  # Dynamic routes for catalog controller and all subsites
  blacklight_for *(SUBSITES['public'].keys.map{|key| key.to_sym}) # Using * operator to turn the array of values into a set of arguments for the blacklight_for method

  SUBSITES['public'].each do |subsite_key, data|
    resources subsite_key, only: [:show] do
      collection do
        put 'publish/:id' => "#{subsite_key}#update"
        delete 'publish/:id' => "#{subsite_key}#destroy"
        get 'publish' => "#{subsite_key}#api_info"
      end
    end
    get "#{subsite_key}/previews/:id" => "#{subsite_key}#preview", as: subsite_key + '_preview', constraints: { id: /[^\?]+/ }
    get "#{subsite_key}/:id/proxies" => "#{subsite_key}#show", as: "#{subsite_key}_root_proxies".to_sym
    get "#{subsite_key}/:id/proxies/*proxy_id" => "#{subsite_key}#show", as: "#{subsite_key}_proxy".to_sym, constraints: { proxy_id: /[^\?]+/ }
    resources(:solr_document, {only: [:show], path: subsite_key.to_s, controller: subsite_key.to_s, :format => 'html'}) do
      member do
        post "track"
      end
    end
  end

  get '/restricted' => 'home#restricted', as: :restricted
  get '/restricted/projects', to: redirect('/restricted')

  if SUBSITES['restricted'].present?
    namespace "restricted" do
      resources 'sites', only: [:index, :show], param: :slug
      blacklight_for *((SUBSITES['restricted'].keys.map{|key| key.to_sym})) # Using * operator to turn the array of values into a set of arguments for the blacklight_for method
      SUBSITES['restricted'].each do |subsite_key, data|
        resources subsite_key, only: [:show] do
          collection do
            put 'publish/:id' => "#{subsite_key}#update"
            delete 'publish/:id' => "#{subsite_key}#destroy"
            get 'publish' => "#{subsite_key}#api_info"
          end
        end
        get "#{subsite_key}/previews/:id" => "#{subsite_key}#preview", as: subsite_key + '_preview', constraints: { id: /[^\?]+/ }
        get "#{subsite_key}/:id/proxies" => "#{subsite_key}#show", as: "#{subsite_key}_root_proxies".to_sym
        get "#{subsite_key}/:id/proxies/*proxy_id" => "#{subsite_key}#show", as: "#{subsite_key}_proxy".to_sym, constraints: { proxy_id: /[^\?]+/ }
        resources(:solr_document, {only: [:show], path: subsite_key.to_s, controller: subsite_key.to_s, :format => 'html'}) do
          member do
            post "track"
          end
        end
      end
    end
  end

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
    resources :bytestreams, path: 'catalog/:catalog_id/bytestreams', only: [:index, :show], constraints: { id: /[^\/]+/ }
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
