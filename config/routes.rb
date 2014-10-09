MediaAnalyse::Application.routes.draw do
  resources :user_sessions
  resources :users
  get '/login' => 'user_sessions#new', as: :login
  match '/logout' => 'user_sessions#destroy', via: :get, as: :logout

  #rss
  get '/efeed' => 'efeed#index', as: :efeed
  get '/show_new_emessages' => 'efeed#show_new_emessages', as: :show_new_emessages
  get '/new_emessages' => 'efeed#new_emessages', as: :new_emessages
  match '/select_esources' => 'efeed#select_esources', via: :post, as: :select_esources
  get '/efeed/style/:style' => 'efeed#style', as: :estyle
  get '/efeed/edit' => 'efeed#edit', as: :edit_efeed
  get '/efeed/new' => 'efeed#new', as: :new_efeed
  match '/efeed/:id' => 'efeed#delete', via: :delete, as: :delete_efeed
  match '/efeed/create' => 'efeed#create', via: :post, as: :create_efeed

  root 'efeed#index'
end
