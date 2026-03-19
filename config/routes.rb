Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"
  get "/contact", to: "pages#contact", as: :contact
  post "/contact", to: "pages#create_contact"
  get "/showcase/company/:client_id", to: "pages#company_showcase", as: :company_showcase
  get "/showcase/company/:client_id/missions", to: "pages#company_missions", as: :company_missions
  get "/showcase/company/:client_id/contributions", to: "pages#company_contributions", as: :company_contributions
  resources :client_posts, only: [] do
    resources :client_post_comments, only: [:create, :update, :destroy], shallow: true do
      resources :client_post_comment_reactions, only: [:create], shallow: true
    end
    resources :client_post_reactions, only: [:create, :destroy], shallow: true
  end
  resources :clients, only: [] do
    resource :subscription, controller: "client_subscriptions", only: [ :create, :destroy ]
  end
  resources :clients
  resources :client_contacts
  resources :freelancer_profiles
  get "/dashboard", to: "missions#dashboard", as: :dashboard
  namespace :admin do
    resources :mission_applications, only: [ :index ] do
      member do
        patch :accept
        patch :reject
      end
    end
  end
  scope "/dashboard", as: :dashboard do
    get "feed", to: "pages#feed", as: :feed
    get "community", to: "pages#community", as: :community
    get "training", to: "pages#training", as: :training
    post "community/messages", to: "pages#create_community_message", as: :community_messages
    delete "community/messages/:id", to: "pages#destroy_community_message", as: :community_message
    post "community/replies", to: "pages#create_community_reply", as: :community_replies
    post "community/reactions", to: "pages#create_community_reaction", as: :community_reactions
    get "missions", to: "missions#index", as: :missions
    get "missions/my", to: "missions#my_missions", as: :my_missions
    get "missions/pending", to: "missions#pending_missions", as: :pending_missions
    get "missions/library", to: "missions#library", as: :library_missions
    get "missions/:id", to: "missions#show", as: :mission
    get "freelancers", to: "freelancer_profiles#index", as: :freelancer_profiles
    get "freelancers/:id", to: "freelancer_profiles#show", as: :freelancer_profile
    get "candidates", to: "candidates#index", as: :candidates
    get "candidates/:id", to: "candidates#show", as: :candidate
    get "finances", to: "freelance_finances#show", as: :freelance_finance
    get "invoices", to: "invoices#index", as: :invoices
    get "todo", to: "todo_lists#show", as: :todo_list
    patch "admin_updates/acknowledge", to: "freelance_admin_updates#acknowledge", as: :acknowledge_freelance_admin_updates
  end
  resources :missions do
    get :my_missions, on: :collection
    get :pending_missions, on: :collection
    patch :toggle_freelance_urgent, on: :member
    patch :close_by_freelance, on: :member
    post :apply, on: :member
    delete :withdraw, on: :member
    collection do
      get :library, as: :library
    end
    member do
      post :toggle_favorite
      get :favoris
    end
  end
  resources :candidates do
    member do
      patch :toggle_favorite
    end
    resources :candidate_notes, only: [ :create, :update, :destroy ]
  end
  resources :placements do
    member do
      patch :validate_compliance
      patch :refuse_compliance
    end
  end
  resources :invoices do
    post :create_note, on: :member
  end
  resources :commissions
  resources :payments
  resource :todo_list, only: [ :show ]
  resources :todo_tasks, only: [ :create, :update, :destroy ]
  resources :todo_categories, only: [ :create, :update, :destroy ]
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
