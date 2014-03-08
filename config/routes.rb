Rails.application.routes.draw do
  scope :module => :staypuft do
    resources :openstack_deployments
  end
end
