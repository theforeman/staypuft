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
      if @deployment.deployed?
        (alert :class => 'alert-warning',
              :text => _('Machines are already deployed with this configuration. Changing the configuration parameters
                          is unsupported and may result in an unusable configuration. <br/>Please proceed with caution.'),
              :close => false).html_safe
      end
    end

    def host_label(host)
      case host
        when Host::Managed
          style ="label-info"
          short = s_("Managed|M")
          label = _('Known Host')
          path  = hash_for_host_path(host)
        when Host::Discovered
          style ="label-default"
          short = s_("Discovered|D")
          label = _('Discovered Host')
          path  = hash_for_discovered_host_path(host) # TODO: this assumes discovery 1.3
        else
          style = 'label-warning'
          short = s_("Error|E")
          path  = '#'
          label = _('Unknown Host')
      end

      content_tag(:span, short, {:rel => "twipsy", :class => "label label-light " + style, :"data-original-title" => _(label)} ) +  link_to(trunc("  #{host}",32), path)
    end
  end

end
