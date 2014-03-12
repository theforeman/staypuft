Rails.application.routes.draw do
  scope :module => :staypuft do
    resources :deployments
    resources :deployment_steps
  end
end
