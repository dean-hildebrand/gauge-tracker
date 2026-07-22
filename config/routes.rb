Rails.application.routes.draw do
  get "up" => "rails/health#show"

  devise_for :users, skip: [ :registrations ]
  resources :gauges, only: [ :index, :new, :create, :show, :edit, :update ] do
    resources :readings, only: [ :new, :create, :edit, :update ], shallow: true
  end

  root "gauges#index"
end
