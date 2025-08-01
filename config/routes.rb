Rails.application.routes.draw do
  resources :clients do
    get "current_rate", on: :member
    resources :invoices, only: [ :new ]
  end
  resources :client_sessions
  resources :messages
  resources :payees

  resources :invoices, only: [ :create, :index, :show, :edit, :update, :destroy ] do
    member do
      post :send_invoice
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "clients#index"
end
