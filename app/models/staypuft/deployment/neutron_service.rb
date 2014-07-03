module Staypuft
  class Deployment::NeutronService < Deployment::AbstractParamScope
    def self.param_scope
      'neutron'
    end

    SEGMENTATION_LIST = ['vxlan', 'vlan', 'gre', 'flat']
    INTERFACE_HELP    = N_('(i.e. eth0, em1, etc.)')
    VLAN_HELP         = N_('[1-4094] (i.e. 10:100)')


    param_attr :network_segmentation, :tenant_vlan_ranges, :networker_tenant_interface,
               :use_external_interface, :external_interface_name, :compute_tenant_interface,
               :use_vlan_for_external_network, :vlan_ranges_for_external_network

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
      HUMAN       = N_('Tenant (VM data) VLAN Ranges')
      HUMAN_AFTER = VLAN_HELP
    end

    validates :tenant_vlan_ranges,
              :presence => true,
              :if       => :vlan_segmentation?
    # TODO: vlan range format validation

    module NetworkerTenantInterface # TODO can be hidden in UI when !#enable_tunneling?
      HUMAN       = N_('Which interface to use for tenant networks:')
      HUMAN_AFTER = INTERFACE_HELP
    end

    validates :networker_tenant_interface,
              :presence => true
    # TODO: interface name format validation

    module UseExternalInterface
      HUMAN = N_('Configure external interface on network node')
    end

    validates :use_external_interface, inclusion: { in: [true, false, 'true', 'false'] }

    module ExternalInterfaceName
      HUMAN       = N_('External interface connected to')
      HUMAN_AFTER = INTERFACE_HELP
    end

    validates :external_interface_name,
              :presence => true,
              :if       => :use_external_interface?
    # TODO: interface name format validation

    module UseVlanForExternalNetwork
      HUMAN = N_('Configure VLAN for external network')
    end

    validates :use_vlan_for_external_network, inclusion: { in: [true, false, 'true', 'false'] }

    module VlanRangesForExternalNetwork
      HUMAN       = N_('VLAN Range for external network')
      HUMAN_AFTER = N_('i.e. 1000:2999')
    end

    validates :vlan_ranges_for_external_network,
              :presence => true,
              :if       => :external_network_vlan?
    # TODO: vlan rangesformat validation

    module ComputeTenantInterface # TODO can be hidden in UI when !#enable_tunneling?
      HUMAN       = N_('Which interface to use for tenant networks:')
      HUMAN_AFTER = INTERFACE_HELP
    end

    validates :compute_tenant_interface,
              :presence => true
    # TODO: interface name format validation

    def set_defaults
      self.network_segmentation   = NetworkSegmentation::VXLAN
      self.use_external_interface = 'false'
    end

    def active?
      deployment.networking == Deployment::Networking::NEUTRON
    end

    # TODO: make this less clumsy w/ consistent handling of true/false values
    def use_external_interface?
      (self.use_external_interface == true) || (self.use_external_interface == 'true')
    end

    # TODO: make this less clumsy w/ consistent handling of true/false values
    def use_vlan_for_external_network?
      (self.use_vlan_for_external_network == true) || (self.use_vlan_for_external_network == 'true')
    end

    # return list of supported segmentation options with selected option at the
    # beginning of the list
    def network_segmentation_list
      [self.network_segmentation, *(SEGMENTATION_LIST - [self.network_segmentation])]
    end

    # TODO: if use_external_interface? without VLAN segmentation, do we need the second array
    # entry only, or should it be []
    def networker_ovs_bridge_mappings
      [("physnet-tenants:br-#{self.networker_tenant_interface}"  unless self.enable_tunneling?),
       ('physnet-external:br-ex' if self.use_external_interface?)].compact
    end

    def networker_ovs_bridge_uplinks
      [("br-#{self.networker_tenant_interface}:#{self.networker_tenant_interface}" unless self.enable_tunneling?),
       ("br-ex:#{self.external_interface_name}" if self.use_external_interface?)
      ].compact
    end

    def compute_ovs_bridge_mappings
      if !self.enable_tunneling?
        ["physnet-tenants:br-#{self.compute_tenant_interface}"]
      else
        []
      end
    end

    def compute_ovs_bridge_uplinks
      if !self.enable_tunneling?
        ["br-#{self.compute_tenant_interface}:#{self.compute_tenant_interface}"]
      else
        []
      end
    end

    def compute_vlan_ranges
      if self.vlan_segmentation?
        ["physnet-tenants:#{self.tenant_vlan_ranges}"]
      else
        []
      end
    end

    def networker_vlan_ranges
      [("physnet-tenants:#{self.tenant_vlan_ranges}" if self.vlan_segmentation?),
       ("physnet-external:#{self.vlan_ranges_for_external_network}" if self.external_network_vlan?)].compact
    end

    def vlan_segmentation?
      self.network_segmentation == NetworkSegmentation::VLAN
    end

    def external_network_vlan?
      self.use_external_interface? && self.use_vlan_for_external_network?
    end

    def enable_tunneling?
      [NetworkSegmentation::VXLAN, NetworkSegmentation::GRE].include?(network_segmentation)
    end

  end
end
