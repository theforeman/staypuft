module Staypuft
  class Deployment::NeutronService < Deployment::AbstractParamScope
    def self.param_scope
      'neutron'
    end

    SEGMENTATION_LIST = ['vxlan', 'vlan', 'gre', 'flat']
    VLAN_HELP         = N_('[1-4094] (e.g. 10:15)')

    param_attr :network_segmentation, :tenant_vlan_ranges

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

    class Jail < Safemode::Jail
      allow :networker_vlan_ranges, :compute_vlan_ranges, :network_segmentation, :enable_tunneling?,
        :tenant_iface, :networker_ovs_bridge_mappings, :networker_ovs_bridge_uplinks,
        :compute_ovs_bridge_mappings, :compute_ovs_bridge_uplinks, :ovs_tunnel_types
    end

    def set_defaults
      self.network_segmentation   = NetworkSegmentation::VXLAN
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
      deployment.network_query.interface_for_host(host, Staypuft::SubnetType::TENANT)
    end

    def external_interface_name(host)
      deployment.network_query.interface_for_host(host, Staypuft::SubnetType::EXTERNAL)
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

    def param_hash
      { 'network_segmentation'       => network_segmentation,
        'tenant_vlan_ranges'         => tenant_vlan_ranges }
    end

  end
end
