module Staypuft
  module DeploymentsHelper
    def deployment_wizard(step)
      wizard_header(
          step,
          _("Deployment Settings"),
          _("Network Configuration"),
          _("Services Overview"),
          _("Services Configuration")
      )
    end

    def is_new
      @deployment.name.empty?
    end

    def alert_if_deployed
      if @deployment.deployed?
        (alert :class => 'alert-warning',
               :text  => _('Machines are already deployed with this configuration. Changing the configuration parameters ' +
                               'is unsupported and may result in an unusable configuration. <br/>Please proceed with caution.'),
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
        style           ="label-default"
        short           = s_("Discovered|D")
        label           = _('Discovered Host')
        # TODO remove after migrating to foreman_discover 1.3.0
        hash_for_method = [:hash_for_discovered_host_path, :hash_for_discover_path].find { |m| respond_to? m }
        path            = send hash_for_method, host
      else
        style = 'label-warning'
        short = s_("Error|E")
        path  = '#'
        label = _('Unknown Host')
      end

      content_tag(:span, short,
                  { :rel                   => "twipsy",
                    :class                 => "label label-light " + style,
                    :"data-original-title" => _(label) }) + link_to(trunc("  #{host}", 32), path)
    end

    # discovered hosts don't have interfaces yet
    def host_nics(host)
      host.respond_to?(:interfaces) ? host.interfaces.physical.order(:identifier).map {|i| html_escape(i.identifier)}.join(tag(:br)).html_safe : ''
    end
  end

end
