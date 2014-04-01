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
        # Collect services across all deployment's roles
        @services = @deployment.roles(:services).map(&:services).flatten.uniq
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
      end

      render_wizard @deployment
    end

    private
    def get_deployment
      @deployment = Deployment.first
    end

    def redirect_to_finish_wizard(options = {})
      redirect_to deployment_path(@deployment), :notice => _("Deployment has been succesfully configured.")
    end
  end
end
