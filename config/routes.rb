Rails.application.routes.draw do
  scope :module => :staypuft do
    resources :deployments do
      collection do
        get 'auto_complete_search'
        post 'associate_host'
      end
      member do
        match '/hostgroup/:hostgroup_id',
              :to => 'deployments#show',
              :as => :show_with_hostgroup_selected, :method => :get
        post 'deploy'
        get 'populate'
        get 'summary'
      end
    end

    resources :deployment_steps
  end
end
