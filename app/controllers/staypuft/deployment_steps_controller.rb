module Staypuft
  class DeploymentStepsController < ApplicationController
    include Wicked::Wizard
    steps :deployment_settings, :services_selection, :services_configuration

    before_filter :get_deployment

    def show
      case step
      when :deployment_settings
        @layouts = Layout.all
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

        @deployment.update_attributes(params[:staypuft_deployment])

        @deployment.hostgroup.name = @deployment.name
        @deployment.hostgroup.save!

        @deployment.layout.roles.each do |role|
          role_hostgroup = Hostgroup.
              joins(:deployment_role_hostgroup, :hostgroup_role).
              where(DeploymentRoleHostgroup.table_name => { deployment_id: @deployment },
                    HostgroupRole.table_name           => { role_id: role }).
              first

          role_hostgroup ||= Hostgroup.nest("#{role.name}", @deployment.hostgroup).tap do |hostgroup|
            hostgroup.build_deployment_role_hostgroup deployment: @deployment
            hostgroup.build_hostgroup_role role: role
          end

          role.puppetclasses.each do |puppetclass|
            unless role_hostgroup.puppetclasses.include?(puppetclass)
              role_hostgroup.puppetclasses << puppetclass
            end
          end
          role_hostgroup.save!
        end
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
