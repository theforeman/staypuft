Rails.application.routes.draw do
  scope :module => :staypuft do
    resources :openstack_deployments
    resources :openstack_deployment_steps
  end
end
