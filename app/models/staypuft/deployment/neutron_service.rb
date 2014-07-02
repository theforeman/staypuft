module Staypuft
  class Deployment::NeutronService < Deployment::AbstractParamScope
    def self.param_scope
      'neutron'
    end

    SEGMENTATION_LIST = ['vxlan', 'vlan', 'gre', 'flat']

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
      HUMAN_AFTER = '[1-4094] (i.e. 10:100)'
    end

    validates :tenant_vlan_ranges,
              :presence => true,
              :if       => :vlan_segmentation?
    # TODO: vlan range format validation

    module NetworkerTenantInterface
      HUMAN       = N_('Which interface to use for tenant networks:')
      HUMAN_AFTER = N_('(i.e. eth0, em1, etc.)')
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
      HUMAN_AFTER = N_('(interface) (i.e. eth1)')
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
      HUMAN_AFTER = N_('i.e. physnet1:1000:2999')
    end

    validates :vlan_ranges_for_external_network,
              :presence => true,
              :if       => :external_network_vlan?
    # TODO: vlan rangesformat validation

    module ComputeTenantInterface
      HUMAN       = N_('Which interface to use for tenant networks:')
      HUMAN_AFTER = N_('(i.e. eth0, em1, etc.)')
    end

    validates :compute_tenant_interface,
              :presence => true
    # TODO: interface name format validation

    def set_defaults
      self.network_segmentation = NetworkSegmentation::VXLAN
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

    def controller_ovs_bridge_mappings
      if self.vlan_segmentation?
        ["physnet-tenants:br-#{self.networker_tenant_interface}",
         ('physnet-external:br-ex' if self.use_external_interface?)].compact
      else
        []
      end
    end

    def controller_ovs_bridge_uplinks
      if self.vlan_segmentation?
        ["br-#{self.networker_tenant_interface}:#{self.networker_tenant_interface}",
         ("br-ex:#{self.external_interface_name}" if self.use_external_interface?)]
      else
        []
      end
    end

    def compute_ovs_bridge_mappings
      if self.vlan_segmentation?
        ["physnet-tenants:br-#{self.compute_tenant_interface}"]
      else
        []
      end
    end

    def compute_ovs_bridge_uplinks
      if self.vlan_segmentation?
        ["br-#{self.compute_tenant_interface}:#{self.compute_tenant_interface}"]
      else
        []
      end
    end

    # FIXME: mapping is off here -- both external and tenant vlan ranges map to the same back end
    # params: fix this with morazi in the AM
    def ml2_network_vlan_ranges
      if self.external_network_vlan?
        [self.vlan_ranges_for_external_network]
      else
        []
      end
    end
    def vlan_segmentation?
      self.network_segmentation == NetworkSegmentation::VLAN
    end

    def external_network_vlan?
      self.use_external_interface? && self.use_vlan_for_external_network?
    end

  end
end
