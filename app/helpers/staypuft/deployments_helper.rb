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

    def is_edit
      @deployment.name.starts_with?(Staypuft::Deployment::NEW_NAME_PREFIX)
      logger.info @deployment.name.starts_with?(Staypuft::Deployment::NEW_NAME_PREFIX)
      logger.info @deployment.name
    end

    def anything_deployed
      @deployment.child_hostgroups.
        # this could be an association on deployment
        inject([]) { |hosts, hg| hosts + hg.hosts }.
        any?
        # (:open_stack_deployed?)
    end

  end
end
