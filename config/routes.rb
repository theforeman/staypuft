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

      resources :interface_assignments, :only => [:index, :create, :destroy]

      resources :bonds, :only => [:create, :destroy] do
        member do
          put 'add_slave'
          put 'remove_slave'
          put 'change_mode'
        end
      end
    end

    resources :subnet_typings, :only => [:create, :destroy, :update]

    scope 'staypuft', as: 'staypuft' do
      resources :subnets
    end
  end
end
