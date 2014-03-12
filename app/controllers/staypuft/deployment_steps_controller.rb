module Staypuft
  class DeploymentStepsController < ApplicationController
    include Wicked::Wizard
    steps :deployment_settings, :services_selection, :services_configuration

    def show
      # @deployment = Deployment.new

      render_wizard
    end

    def update
      # TODO(jtomasek): delete this info when Deployment model is done
      # we can use 'case' if we need to distinquish among steps
      # render_wizard @deployment will try to call save on that object
      # if validations fail, wizard renders submitted steps
      # in model we need to conditionally validate based on the step eg:
      # validates_presence_of :some_attribute, :if => :on_deployment_settings_step?
      # see wicked wiki for more info

      #case step
      #when :deployment_settings
      #  @deployment.update_attributes(params[:deployment])
      #end
      #render_wizard @deployment

      render_wizard
    end

  private

    def redirect_to_finish_wizard
      redirect_to deployments_path, :notice => "Deployment has been succesfully configured."
    end
  end
end
