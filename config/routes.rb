Rails.application.routes.draw do
  get "up" => "rails/health#show"

  devise_for :users, skip: [ :registrations ]
  resources :gauges, only: [ :index, :new, :create, :show, :edit, :update ]

  root "gauges#index"
end
