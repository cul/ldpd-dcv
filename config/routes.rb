Dcv::Application.routes.draw do
  root :to => "catalog#index"

  get '/collections' => 'pages#collections', as: :all_collections

  blacklight_for :catalog, :lindquist, :css

  devise_for :users

  get 'catalog/:id/children' => 'children#index', as: :children

  resources :bytestreams, path: '/catalog/:catalog_id/bytestreams' do
#    get '/:id/content' => 'bytestreams#content', as: :bytestream_content
  end
  get '/catalog/:catalog_id/bytestreams/:id/content' => 'bytestreams#content', as: :bytestream_content

#  get 'catalog/:id/bytestreams' => 'bytestreams#index', as: :bytestreams
#  get 'catalog/:id/bytestreams/:dsid' => 'bytestreams#show', as: :bytestreams

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

  get '/resolve/:resolve/:id',
    :to => CatalogController.action(:resolve),
    :as => :resolver,
    :constraints => {
      :id => /([^\/]).+/,
      :resolve => /(catalog|thumbs|bytestreams)/
    }

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
