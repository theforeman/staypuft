Rails.application.routes.draw do
  scope :module => :staypuft do
    resources :deployments do
      collection do
        get 'auto_complete_search'
      end
      member do
        match '/hostgroup/:hostgroup_id',
              :to => 'deployments#show',
              :as => :show_with_hostgroup_selected, :method => :get
        post 'deploy'
        get 'populate'
        get 'summary'
        post 'associate_host'
        post 'unassign_host'
        get 'export_config'
        post 'import_config'
      end

      resources :steps
    end

  end
end
