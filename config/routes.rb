Rails.application.routes.draw do
  root "posts#index"

  resource :session, only: %i[new create destroy]
  get "/login", to: "sessions#new", as: :login
  delete "/logout", to: "sessions#destroy", as: :logout
  post "/api/auth/login", to: "sessions#create", defaults: { format: :json }
  get "/api/auth/me", to: "sessions#show", defaults: { format: :json }

  resources :posts, param: :slug do
    resources :comments, only: :create
    resources :revisions, only: %i[index show] do
      member { post :restore }
    end
    member do
      post :submit
      post :publish
      post :reject
      post :archive
    end
  end

  get "/editorial", to: "posts#editorial", as: :editorial
  resources :comments, only: :index do
    member { post :moderate }
  end
  resources :categories, except: :show
  resources :tags, except: :show
  resource :search, only: :show
  get "/feed", to: "feeds#show", defaults: { format: :rss }, as: :feed
  get "/media/:signed_id/:filename", to: "media#show", as: :media
  resource :export, only: :show
  resource :import, only: %i[new create]
  get "/health", to: "health#show"
end
