Dcv::Application.routes.draw do
  root :to => "catalog#home"

  get '/browse' => 'catalog#browse'
  get '/welcome' => 'welcome#home'

  get '/catalog/get_random_item' => 'catalog#get_random_item'
  get '/catalog/get_pivot_facet_data' => 'catalog#get_pivot_facet_data'
  blacklight_for :catalog, :lindquist, :css

  get '/users/do_wind_login' => 'users#do_wind_login', as: :do_wind_login
  devise_for :users

  resources :children, path: 'catalog/:parent_id/children', only: [:index, :show]

  resources :bytestreams, path: '/catalog/:catalog_id/bytestreams' do
    get 'content' => 'bytestreams#content'
  end

  resources(:solr_document, {only: [:show], path: 'lindquist', controller: 'lindquist'}) do
    member do
      post "track"
    end
  end

  resources(:solr_document, {only: [:show], path: 'css', controller: 'css'}) do
    member do
      post "track"
    end
  end

  resources :thumbs, only: [:show]

  resources :screens, only: [:show], controller: :screen_images

  namespace :resolve do
    resources :catalog, only: [:show], constraints: { id: /[^\?]+/ } do
      resources :bytestreams, only: [:index, :show] do
        get 'content'=> 'bytestreams#content'
      end
    end
    resources :thumbs, only: [:show], constraints: { id: /[^\?]+/ }
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
