module Staypuft
  class StepsController < Staypuft::ApplicationController
    include Wicked::Wizard
    steps :deployment_settings, :services_overview, :services_configuration

    before_filter :get_deployment

    def show
      case step
      when :deployment_settings
        @layouts = ordered_layouts
      when :services_configuration
        @services_map = [:nova, :neutron, :glance, :cinder]
      end

      render_wizard
    end

    def update
      case step

      when :deployment_settings
        @layouts               = ordered_layouts
        # FIXME: why don't we reset wizard step on the second time through (i.e. after complete?)
        # now that we're validating associated services when the form is at CONFIGURATION or COMPLETE
        # changing anything that might affect active services could cause validation problems (i.e.
        # can't change from Nova to Neutron, since the change to 'neutron' will activate neutron
        # validation, which of course can't be valid yet since we haven't presented the user with
        # form step 3. Any downside to setting this back?
        @deployment.form_step  = Deployment::STEP_SETTINGS unless @deployment.form_complete?
        @deployment.passwords.attributes = params[:staypuft_deployment].delete(:passwords)
        @deployment.attributes = params[:staypuft_deployment]

      when :services_overview
        @deployment.form_step = Deployment::STEP_OVERVIEW unless @deployment.form_complete?

      when :services_configuration
        @services_map = [:nova, :neutron, :glance, :cinder]
        if params[:staypuft_deployment]
          @deployment.form_step = Deployment::STEP_CONFIGURATION unless @deployment.form_complete?
          @services_map.each do |service|
            @deployment.send(service).attributes = params[:staypuft_deployment].delete(service)
          end
        end
      else
        raise 'unknown step'
      end

      render_wizard @deployment
    end

    private
    def get_deployment
      @deployment      = Deployment.find(params[:deployment_id])
      @deployment.name = nil if @deployment.name.starts_with?(Deployment::NEW_NAME_PREFIX)
    end

    def redirect_to_finish_wizard(options = {})
      redirect_to deployment_path(@deployment), :notice => _("Deployment has been succesfully configured.")
    end

    def ordered_layouts
      Layout.order(:name).order("networking DESC").all
    end
  end
end
