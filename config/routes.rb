Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"
  resources :clients
  resources :client_contacts
  resources :freelancer_profiles
  resources :missions do
    get :my_missions, on: :collection
    get :pending_missions, on: :collection
    patch :toggle_freelance_urgent, on: :member
    post :apply, on: :member
  end
  resources :candidates
  resources :placements
  resources :invoices do
    post :create_note, on: :member
  end
  resources :commissions
  resources :payments
  resource :freelance_finance, only: [ :show ] do
    post :create_client_invoice
    post :create_freelancer_invoice
    post :create_payout_request
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
