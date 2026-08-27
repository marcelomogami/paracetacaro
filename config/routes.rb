Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ],
    controllers: { sessions: "users/sessions" },
    path: "",
    path_names: { sign_in: "login", sign_out: "logout", password: "password" }

  get "up" => "rails/health#show", as: :rails_health_check

  get  "cadastro", to: "admin/users#new",    as: :cadastro
  post "cadastro", to: "admin/users#create"

  namespace :admin do
    resources :users, only: [ :index, :edit, :update, :destroy ]
  end

  get  "setup", to: "setup#new",    as: :setup
  post "setup", to: "setup#create"

  resource :cart, only: [ :show, :destroy ] do
    get :checkout, on: :member
  end
  resources :cart_selections, only: [ :create, :destroy ]

  get "changelog", to: "pages#changelog", as: :changelog

  root "searches#index"
end
