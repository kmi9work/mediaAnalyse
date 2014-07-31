MediaAnalyse::Application.routes.draw do
  resources :user_sessions
  resources :users
  get 'login' => 'user_sessions#new', as: :login
  match 'logout' => 'user_sessions#destroy', via: :get, as: :logout

  mount Delayed::Web::Engine, at: '/jobs'
  get 'queries/:id/chart_data' => 'queries#chart_data', as: :chart_data
  get '/texts/:id/feedback' => 'texts#feedback', as: :feedback
  get '/negative_category' => 'categories#negative_category', as: :negative_category
  delete '/essence/:id' => 'essences#destroy', as: :essence
  match '/texts/:id/commit_essence' => 'essences#commit_essence', via: :post, as: :commit_essence
  get '/texts/:id/get_text' => 'texts#get_text', as: :get_text
  get '/texts/:id/get_emot' => 'texts#get_emot', as: :get_emot
  get '/queries/new(.:format)' => 'queries#new', as: :new_query
  match "/queries" => 'queries#create', via: :post, as: :queries
  get '/queries/:query_id/start_work' => 'queries#start_work', as: :start_work
  get '/queries/:query_id/stop_work' => 'queries#stop_work', as: :stop_work
  get '/texts/get_new_links' => 'texts#get_new_links', as: :get_new_links
  get '/disable_tracking' => 'application#disable_tracking', as: :disable_tracking
  get '/enable_tracking' => 'application#enable_tracking', as: :enable_tracking

  resources :categories do
    resources :queries do
      resources :texts
    end
  end
  
  root 'categories#index'
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
