module Staypuft
  class Deployment::NeutronService < Deployment::AbstractParamScope
    def self.param_scope
      'neutron'
    end

    SEGMENTATION_LIST   = ['vxlan', 'vlan', 'gre', 'flat']
    VLAN_HELP           = N_('[1-4094] (e.g. 10:15)')
    ML2MECHANISM_TYPES  = :ml2_openvswitch, :ml2_l2population, :ml2_cisco_nexus
    N1KV_PARAMS         = :n1kv_vsm_ip, :n1kv_vsm_password

    param_attr :network_segmentation, :tenant_vlan_ranges, :core_plugin, :network_device_mtu,
               *ML2MECHANISM_TYPES, *N1KV_PARAMS
    param_attr_array :nexuses => Cisconexus

    module NetworkSegmentation
      VXLAN  = 'vxlan'
      GRE    = 'gre'
      VLAN   = 'vlan'
      FLAT   = 'flat'
      LABELS = { VXLAN => N_('VXLAN Segmentation'),
                 GRE   => N_('GRE Segmentation'),
                 VLAN  => N_('VLAN Segmentation'),
                 FLAT  => N_('Flat') }
      TYPES  = LABELS.keys
      HUMAN  = N_('Tenant Network Type')
    end

    validates :network_segmentation, presence: true, inclusion: { in: NetworkSegmentation::TYPES }

    module CorePlugin
      ML2    = 'ml2'
      N1KV   = 'n1kv'
      LABELS = { ML2 => N_("ML2 Core Plugin"),
                 N1KV => N_("N1KV Core Plugin") }
      MODULES = { ML2 => 'neutron.plugins.ml2.plugin.Ml2Plugin',
                  N1KV => 'neutron.plugins.cisco.network_plugin.PluginV2'}
      TYPES  = LABELS.keys
      HUMAN  = N_('Core Plugin Type')
    end

    validates :core_plugin, presence: true, inclusion: { in: CorePlugin::TYPES }

    module TenantVlanRanges
      HUMAN       = N_('Tenant (VM Data) VLAN Ranges')
      HUMAN_AFTER = VLAN_HELP
    end

    class NeutronVlanRangesValidator < ActiveModel::EachValidator
      include Staypuft::Deployment::VlanRangeValuesValidator
    end

    validates :tenant_vlan_ranges,
              :presence            => true,
              :if                  => :vlan_segmentation?,
              :neutron_vlan_ranges => true

    class N1kvIpAddressValidator < ActiveModel::EachValidator
      include Staypuft::Deployment::IpAddressValidator
    end

    validates :n1kv_vsm_ip,
              :presence        => true,
              :if              => :n1kv_plugin?,
              :n1kv_ip_address => true
    validates :n1kv_vsm_password,
              :presence        => true,
              :if              => :n1kv_plugin?

    module Ml2Mechanisms
      OPENVSWITCH = 'openvswitch'
      L2POPULATION = 'l2population'
      CISCO_NEXUS = 'cisco_nexus'
      LABELS = { OPENVSWITCH => N_('Open vSwitch'),
                 L2POPULATION => N_('L2 Population'),
                 CISCO_NEXUS => N_('Cisco Nexus') }
      TYPES = LABELS.keys
      HUMAN = N_('ML2 Mechanism Drivers')
    end
    validate  :at_least_one_mechanism_selected,
              :if          => :ml2_plugin?
    validate  :cisco_nexuses,
              :if          => [:ml2_plugin?, :cisco_nexus_mechanism?]
    validates :nexuses,
              :presence   => true,
              :if         => [:ml2_plugin?, :cisco_nexus_mechanism?]

    module Mtu
      HUMAN           = N_('Tenant Network Device MTU')
      HUMAN_AFTER     = N_('(Optional) Only set this if changing the default')
    end

    validates :network_device_mtu, numericality: { only_integer: true }, allow_blank: true

    def compute_network_device_mtu
      # Note: This should only be used for setting the puppet params, not for the
      # physical interfaces
      this.enable_tunneling? ? this.network_device_mtu - 50 : this.network_device_mtu
    end

    class Jail < Safemode::Jail
      allow :networker_vlan_ranges, :compute_vlan_ranges, :network_segmentation, :enable_tunneling?,
        :tenant_iface, :networker_ovs_bridge_mappings, :networker_ovs_bridge_uplinks,
        :compute_ovs_bridge_mappings, :compute_ovs_bridge_uplinks, :ovs_tunnel_types,
        :openvswitch_mechanism?, :l2population_mechanism?, :cisco_nexus_mechanism?,
        :ml2_mechanisms, :nexuses, :active?, :compute_cisco_nexus_config, :core_plugin,
        :ml2_plugin?, :n1kv_plugin?, :n1kv_vsm_ip, :n1kv_vsm_password,
        :core_plugin_module, :network_device_mtu, :compute_network_device_mtu
    end

    def set_defaults
      self.network_segmentation   = NetworkSegmentation::VXLAN
      self.core_plugin = CorePlugin::ML2
      self.ml2_openvswitch = "true"
      self.ml2_l2population = "true"
      self.ml2_cisco_nexus = "false"
      self.network_device_mtu = nil
    end

    def active?
      deployment.networking == Deployment::Networking::NEUTRON
    end

    # return list of supported segmentation options with selected option at the
    # beginning of the list
    def network_segmentation_list
      [network_segmentation, *(SEGMENTATION_LIST - [network_segmentation])]
    end

    def networker_ovs_bridge_mappings(host)
      compute_ovs_bridge_mappings(host) + [*('physnet-external:br-ex' if external_interface_name(host))]
    end

    def networker_ovs_bridge_uplinks(host)
      compute_ovs_bridge_uplinks(host) + [*("br-ex:#{external_interface_name(host)}" if external_interface_name(host))]
    end

    def compute_ovs_bridge_mappings(host)
      [*("physnet-tenants:br-#{tenant_iface(host)}" if !enable_tunneling?)]
    end

    def compute_ovs_bridge_uplinks(host)
      [*("br-#{tenant_iface(host)}:#{tenant_iface(host)}" if !enable_tunneling?)]
    end

    def compute_vlan_ranges
      [*("physnet-tenants:#{tenant_vlan_ranges}" if vlan_segmentation?)]
    end

    def networker_vlan_ranges
      compute_vlan_ranges << "physnet-external"
    end

    def vlan_segmentation?
      network_segmentation == NetworkSegmentation::VLAN
    end

    def enable_tunneling?
      [NetworkSegmentation::VXLAN, NetworkSegmentation::GRE].include?(network_segmentation)
    end

    def tenant_iface(host)
      deployment.network_query.interface_for_host(Staypuft::SubnetType::TENANT, host)
    end

    def external_interface_name(host)
      deployment.network_query.interface_for_host(Staypuft::SubnetType::EXTERNAL, host)
    end

    def ovs_tunnel_types
      case network_segmentation
      when NetworkSegmentation::VXLAN
        ['vxlan']
      when NetworkSegmentation::GRE
        ['gre']
      else
        []
      end
    end

    def openvswitch_mechanism?
      self.ml2_openvswitch == "true"
    end

    def l2population_mechanism?
      self.ml2_l2population == "true"
    end

    def cisco_nexus_mechanism?
      self.ml2_cisco_nexus == "true"
    end

    def ml2_plugin?
      self.core_plugin == CorePlugin::ML2
    end

    def n1kv_plugin?
      self.core_plugin == CorePlugin::N1KV
    end

    def core_plugin_module
      CorePlugin::MODULES[self.core_plugin]
    end

    def compute_cisco_nexus_config
      Hash[nexuses.map { |nexus| [nexus.hostname, nexus.config_hash] }]
    end

    def ml2_mechanisms
      Ml2Mechanisms::TYPES.map { |ml2_type| ml2_type if self.send("#{ml2_type}_mechanism?") }.compact
    end

    def param_hash
      { 'network_segmentation'       => network_segmentation,
        'core_plugin'                => core_plugin,
        'tenant_vlan_ranges'         => tenant_vlan_ranges,
        'ml2_openvswitch'            => ml2_openvswitch,
        'ml2_l2population'           => ml2_l2population,
        'ml2_cisco_nexus'            => ml2_cisco_nexus,
        'nexuses'                    => nexuses,
        'n1kv_vsm_ip'                => n1kv_vsm_ip,
        'n1kv_vsm_password'          => n1kv_vsm_password }
    end

    private

    def at_least_one_mechanism_selected
      if ml2_mechanisms.empty?
        errors.add :base, _("At least one ML2 mechanism must be selected")
      end
    end

    def cisco_nexuses
      unless self.nexuses.all? { |item| item.valid? }
        errors.add :base, _("Please fix the problems in selected mechanisms")
      end
    end

  end
end
