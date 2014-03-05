module Ofi
  class Engine < ::Rails::Engine

    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]

    # Add any db migrations
    initializer "ofi.load_app_instance_data" do |app|
      app.config.paths['db/migrate'] += Ofi::Engine.paths['db/migrate'].existent
    end

    initializer 'ofi.register_plugin', :after=> :finisher_hook do |app|
      Foreman::Plugin.register :ofi do
        requires_foreman '>= 1.4'
        sub_menu :top_menu, :content_menu, :caption => N_('OpenStack Installer'), :after => :infrastructure_menu do
          menu :top_menu, :openstack_deployments,
               :url_hash => {:controller=> :openstack_deployments, :action=>:index},
               :caption=> N_('Deployments')
        end
      end
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        Ofi::Engine.load_seed
      end
    end

    initializer "ofi.register_actions", :before => 'foreman_tasks.initialize_dynflow' do |app|
      ForemanTasks.dynflow.require!
      action_paths = %W[#{Ofi::Engine.root}/app/lib/actions]
      ForemanTasks.dynflow.config.eager_load_paths.concat(action_paths)
    end

  end
end
