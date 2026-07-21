Rails.application.routes.draw do
  get "up" => "rails/health#show"

  devise_for :users, skip: [ :registrations ]
  root "gauges#index"
end
