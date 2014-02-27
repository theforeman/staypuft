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
      end
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        Ofi::Engine.load_seed
      end
    end

  end
end
