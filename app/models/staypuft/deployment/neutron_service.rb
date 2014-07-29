module Staypuft
  class Deployment::NeutronService < Deployment::AbstractParamScope
    def self.param_scope
      'neutron'
    end

    SEGMENTATION_LIST = ['vxlan', 'vlan', 'gre', 'flat']
    INTERFACE_HELP    = N_('(e.g. eth0 or em1)')
    VLAN_HELP         = N_('[1-4094] (e.g. 10:15)')


    param_attr :network_segmentation, :tenant_vlan_ranges, :networker_tenant_interface,
               :use_external_interface, :external_interface_name, :compute_tenant_interface

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

    module NetworkerTenantInterface
      HUMAN       = N_('Which interface to use for tenant networks')
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

    module ComputeTenantInterface
      HUMAN       = N_('Which interface to use for tenant networks')
      HUMAN_AFTER = INTERFACE_HELP
    end

    validates :compute_tenant_interface,
              :presence => true
    # TODO: interface name format validation

    class Jail < Safemode::Jail
      allow :networker_vlan_ranges, :compute_vlan_ranges, :network_segmentation, :enable_tunneling?,
        :networker_tenant_interface, :networker_ovs_bridge_mappings, :networker_ovs_bridge_uplinks,
        :compute_tenant_interface, :compute_ovs_bridge_mappings, :compute_ovs_bridge_uplinks
    end

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

    # return list of supported segmentation options with selected option at the
    # beginning of the list
    def network_segmentation_list
      [self.network_segmentation, *(SEGMENTATION_LIST - [self.network_segmentation])]
    end

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
       "physnet-external"].compact
    end

    def vlan_segmentation?
      self.network_segmentation == NetworkSegmentation::VLAN
    end

    def enable_tunneling?
      [NetworkSegmentation::VXLAN, NetworkSegmentation::GRE].include?(network_segmentation)
    end

    def param_hash
      { 'network_segmentation'       => network_segmentation,
        'tenant_vlan_ranges'         => tenant_vlan_ranges,
        'networker_tenant_interface' => networker_tenant_interface,
        'use_external_interface'     => use_external_interface,
        'external_interface_name'    => external_interface_name,
        'compute_tenant_interface'   => compute_tenant_interface }
    end

  end
end
