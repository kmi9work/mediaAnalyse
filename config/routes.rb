MediaAnalyse::Application.routes.draw do
  resources :user_sessions
  resources :users
  get '/login' => 'user_sessions#new', as: :login
  match '/logout' => 'user_sessions#destroy', via: :get, as: :logout
  get '/queries/:query_id/change_interval' => 'queries#change_interval', as: :change_interval

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

  get '/queries/:query_id/keyphrases' => 'queries#keyphrases' , as: :query_keyphrases
  match '/queries/:query_id/commit_keyphrase' => 'keyphrases#commit_keyphrase', via: :post, as: :commit_keyphrase
  delete '/keyphrase/:id' => 'keyphrases#destroy', as: :keyphrase

  get '/queries/:query_id/keyqueries' => 'queries#keyqueries' , as: :query_keyqueries
  match '/queries/:query_id/commit_keyquery' => 'keyqueries#commit_keyquery', via: :post, as: :commit_keyquery
  delete '/keyquery/:id' => 'keyqueries#destroy', as: :keyquery

  get '/queries/:query_id/chart_data' => 'queries#chart_data', as: :chart_data
  get '/texts/:id/feedback' => 'texts#feedback', as: :feedback
  get '/negative_category' => 'categories#negative_category', as: :negative_category
  delete '/essence/:id' => 'essences#destroy', as: :essence
  match '/texts/:id/commit_essence' => 'essences#commit_essence', via: :post, as: :commit_essence
  get '/texts/:id/get_text' => 'texts#get_text', as: :get_text
  get '/texts/:id/get_emot' => 'texts#get_emot', as: :get_emot
  get '/queries/new(.:format)' => 'queries#new', as: :new_query
  match "/queries" => 'queries#create', via: :post, as: :queries

  # category_id
  get '/categories(.:format)' => 'categories#index', as: :categories
  match '/categories(.:format)' => 'categories#create', via: :post
  get '/categories/new(.:format)' => 'categories#new', as: :new_category
  get '/categories/:category_id/edit(.:format)' => 'categories#edit', as: :edit_category
  get '/categories/:category_id(.:format)' => 'categories#show', as: :category
  match '/categories/:category_id(.:format)' => 'categories#update',  via: :patch
  match '/categories/:category_id(.:format)' => 'categories#update',  via: :put
  match '/categories/:category_id(.:format)' => 'categories#destroy', via: :delete

  # query_id
  get '/queries/:query_id/edit(.:format)' => 'queries#index', as: :edit_query
  get '/queries/:query_id(.:format)' => 'queries#show', as: :query
  match '/queries/:query_id(.:format)' => 'queries#update',  via: :patch
  match '/queries/:query_id(.:format)' => 'queries#update',  via: :put
  match '/queries/:query_id(.:format)' => 'queries#destroy', via: :delete
  resources :queries

  # query_id
  get '/categories/:category_id/queries(.:format)' => 'queries#index', as: :category_queries
  match '/categories/:category_id/queries(.:format)' => 'queries#create', via: :post
  get '/categories/:category_id/queries/new(.:format)' => 'queries#new', as: :new_category_query
  get '/categories/:category_id/queries/:query_id/edit(.:format)' => 'queries#edit', as: :edit_category_query
  get '/categories/:category_id/queries/:query_id(.:format)' => 'queries#show', as: :category_query
  match '/categories/:category_id/queries/:query_id(.:format)' => 'queries#update', via: :patch
  match '/categories/:category_id/queries/:query_id(.:format)' => 'queries#update', via: :put
  match '/categories/:category_id/queries/:query_id(.:format)' => 'queries#destroy', via: :delete

  resources :categories do
    resources :queries do
      resources :texts
    end
  end

  root 'categories#index'
end
