module Staypuft
  class DeploymentStepsController < ApplicationController
    include Wicked::Wizard
    steps :deployment_settings, :services_selection, :services_configuration

    before_filter :get_deployment

    def show
      case step
      when :deployment_settings
        @layouts = Layout.all
      when :services_configuration
        @services = @deployment.services
      end

      render_wizard
    end

    def update
      # TODO(jtomasek):
      # in model we need to conditionally validate based on the step eg:
      # validates_presence_of :some_attribute, :if => :on_deployment_settings_step?
      # see wicked wiki for more info

      case step
      when :deployment_settings
        @layouts = Layout.all

        Deployment.transaction do
          @deployment.update_attributes(params[:staypuft_deployment])
          @deployment.update_hostgroup_list
        end
      when :services_configuration
        # Collect services across all deployment's roles
        @services = @deployment.roles(:services).map(&:services).flatten.uniq
        if params[:staypuft_deployment]
          param_data = params[:staypuft_deployment][:hostgroup_params]
          diffs = []
          param_data.each do |hostgroup_id, hostgroup_params|
            hostgroup = Hostgroup.find(hostgroup_id)
            hostgroup_params[:puppetclass_params].each do |puppetclass_id, puppetclass_params|
              puppetclass = Puppetclass.find(puppetclass_id)
              puppetclass_params.each do |param_name, param_value|
                hostgroup.set_param_value_if_changed(puppetclass, param_name, param_value)
              end
            end
          end
        end
      end

      render_wizard @deployment
    end

    private
    def get_deployment
      @deployment = Deployment.first
      @deployment.name = nil if @deployment.name.starts_with?(Deployment::NEW_NAME_PREFIX)
    end

    def redirect_to_finish_wizard(options = {})
      redirect_to deployment_path(@deployment), :notice => _("Deployment has been succesfully configured.")
    end
  end
end
