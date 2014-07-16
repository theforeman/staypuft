Rails.application.routes.draw do
  scope :module => :staypuft do
    resources :deployments do
      collection do
        get 'auto_complete_search'
      end
      member do
        post 'deploy'
        get 'populate'
        get 'summary'
        get 'edit'
        post 'associate_host'
        post 'unassign_host'
        get 'export_config'
        post 'import_config'
      end

      resources :steps
    end

  end
end
