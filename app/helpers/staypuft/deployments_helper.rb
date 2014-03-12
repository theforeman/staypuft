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
  end
end
