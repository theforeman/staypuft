module Staypuft
  module DeploymentsHelper
    def deployment_wizard(step)
      wizard_header(
        step,
         _("Deployment Settings"),
         _("Services Selection"),
         _("Services Configuration")
      )
    end

    def is_new
      @deployment.name.empty?
    end

    def alert_if_deployed
      if @deployment.hosts.any?(&:open_stack_deployed?)
        alert :class => 'alert-warning',
              :text => _('Machines are already deployed with this configuration. Changing the configuration parameters
                          is unsupported and may result in an unusable configuration. <br/>Please proceed with caution.'),
              :close => false
      end
    end

  end
end
