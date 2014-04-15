module Staypuft
  ENGINE_NAME = "staypuft"
  class Engine < ::Rails::Engine
    engine_name Staypuft::ENGINE_NAME

    config.autoload_paths += Dir["#{config.root}/app/lib"]

    # Add any db migrations
    initializer "staypuft.load_app_instance_data" do |app|
      app.config.paths['db/migrate'] += Staypuft::Engine.paths['db/migrate'].existent
    end

    initializer 'staypuft.register_plugin', :after => :finisher_hook do |app|
      Foreman::Plugin.register :staypuft do
        requires_foreman '>= 1.4'
        sub_menu :top_menu, :content_menu, :caption => N_('OpenStack Installer'), :after => :infrastructure_menu do
          menu :top_menu, :openstack_deployments,
               :url_hash => { :controller => 'staypuft/deployments', :action => :index },
               :caption  => N_('Deployments')
        end
      end
    end

    config.to_prepare do
      ::Host::Managed.send :include, Staypuft::Concerns::HostOrchestrationBuildHook
      ::Host::Managed.send :include, Staypuft::Concerns::HostOpenStackAffiliation
      ::Host::Discovered.send :include, Staypuft::Concerns::HostOpenStackAffiliation
      ::Puppetclass.send :include, Staypuft::Concerns::PuppetclassExtensions
      ::Hostgroup.send :include, Staypuft::Concerns::HostgroupExtensions
      ::Environment.send :include, Staypuft::Concerns::EnvironmentExtensions
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        Staypuft::Engine.load_seed
      end
    end

    initializer "staypuft.register_actions", :before => 'foreman_tasks.initialize_dynflow' do |app|
      ForemanTasks.dynflow.require!
      action_paths = %W[#{Staypuft::Engine.root}/app/lib/actions]
      ForemanTasks.dynflow.config.eager_load_paths.concat(action_paths)
    end

    initializer "staypuft.assets.precompile" do |app|
      app.config.assets.precompile += %w(staypuft/staypuft.css staypuft/staypuft.js)
    end

    initializer "load default settings" do |app|
      if (Setting.table_exists? rescue false)
        Setting::StaypuftProvisioning.load_defaults
      end
    end

    initializer 'staypuft.configure_assets', :group => :assets do
      SETTINGS[:staypuft] =
          { assets: { precompile: %w(staypuft/staypuft.js staypuft/staypuft.css) } }
    end

  end

  def table_name_prefix
    Staypuft::ENGINE_NAME + '_'
  end

  def self.table_name_prefix
    Staypuft::ENGINE_NAME + '_'
  end

  def use_relative_model_naming
    true
  end

end
