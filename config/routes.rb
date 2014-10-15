Dcv::Application.routes.draw do
  root :to => "home#index"

  get '/browse/:action' => 'browse', as: :browse
  get '/explore' => 'welcome#home'
  get '/about' => 'pages#about', as: :about
  get '/terms_of_use' => redirect('http://library.columbia.edu/about/policies/copyright-online-collections.html'), as: :terms_of_use

  get '/catalog/get_random_item' => 'catalog#get_random_item'
  get '/catalog/:id/mods' => 'catalog#mods', as: :item_mods
  get '/catalog/:id/citation/:type' => 'catalog#citation', as: :item_citation

  get '/data/flare' => 'catalog#get_pivot_facet_data', as: :flare_data

  # Dynamic routes for catalog controller and all subsites
  blacklight_for *([:catalog].concat(SUBSITES['public'].keys.map{|key| key.to_sym})) # Using * operator to turn the array of values into a set of arguments for the blacklight_for method

  get "catalog/asset/:id/:type/:size.:format" => "catalog#asset" , as: 'catalog_asset'
  get "catalog/resolve/asset/:id/:type/:size.:format" => "catalog#resolve_asset", as: 'catalog_resolve_asset', constraints: { id: /[^\?]+/ }
  get "catalog/asset/:id/:image_format.json" => "catalog#asset_info", as: 'catalog_asset_info'
  get "catalog/resolve/asset/:id/:image_format.json" => "catalog#resolve_asset_info", as: 'catalog_resolve_asset_info', constraints: { id: /[^\?]+/ }

  SUBSITES['public'].each do |subsite_key, data|
    get "#{subsite_key}/asset/:id/:type/:size.:format" => "#{subsite_key}#asset", as: subsite_key + '_asset'
    get "#{subsite_key}/resolve/asset/:id/:type/:size.:format" => "#{subsite_key}#resolve_asset", as: subsite_key + '_resolve_asset', constraints: { id: /[^\?]+/ }
    get "#{subsite_key}/asset/:id/:image_format.json" => "#{subsite_key}#asset_info", as: subsite_key + '_asset_info'
    get "#{subsite_key}/resolve/asset/:id/:image_format.json" => "#{subsite_key}#resolve_asset_info", as: subsite_key + '_resolve_asset_info', constraints: { id: /[^\?]+/ }

    resources(:solr_document, {only: [:show], path: subsite_key.to_s, controller: subsite_key.to_s}) do
      member do
        post "track"
      end
    end
  end

  namespace "restricted" do
    blacklight_for *((SUBSITES['restricted'].keys.map{|key| key.to_sym})) # Using * operator to turn the array of values into a set of arguments for the blacklight_for method
    SUBSITES['restricted'].each do |subsite_key, data|
      get "#{subsite_key}/asset/:id/:type/:size.:format" => "#{subsite_key}#asset", as: subsite_key + '_asset'
      get "#{subsite_key}/resolve/asset/:id/:type/:size.:format" => "#{subsite_key}#resolve_asset", as: subsite_key + '_resolve_asset', constraints: { id: /[^\?]+/ }
      get "#{subsite_key}/asset/:id/:image_format.json" => "#{subsite_key}#asset_info", as: subsite_key + '_asset_info'
      get "#{subsite_key}/resolve/asset/:id/:image_format.json" => "#{subsite_key}#resolve_asset_info", as: subsite_key + '_resolve_asset_info', constraints: { id: /[^\?]+/ }
      resources(:solr_document, {only: [:show], path: subsite_key.to_s, controller: subsite_key.to_s}) do
        member do
          post "track"
        end
      end
    end
  end

  get '/users/do_wind_login' => 'users#do_wind_login', as: :do_wind_login
  devise_for :users

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
