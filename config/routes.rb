Rails.application.routes.draw do
  scope :module => :staypuft do
    resources :deployments do
      collection do
        get 'auto_complete_search'
      end
      member do
        get 'deploy'
        get 'populate'
      end
    end

    resources :deployment_steps
  end
end
