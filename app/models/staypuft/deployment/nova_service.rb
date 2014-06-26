module Staypuft
  class Deployment::NovaService < Deployment::AbstractParamScope
    def self.param_scope
      'nova'
    end

    param_attr :network_manager, :vlan_range, :external_interface_name, :public_floating_range,
               :compute_tenant_interface, :private_fixed_range

    module NetworkManager
      FLAT_DHCP = 'FlatDHCPManager'
      VLAN      = 'VlanManager'
      LABELS    = { FLAT_DHCP => N_('FlatDHCP'),
                    VLAN      => N_('VLAN') }
      TYPES     = LABELS.keys
      HUMAN     = N_('Network Type')
    end
    validates :network_manager, presence: true, inclusion: { in: NetworkManager::TYPES }

    module VlanRange
      HUMAN       = N_('VLAN Range')
      HUMAN_AFTER = '[0-4094]'
    end
    validates :vlan_range,
              :presence => true,
              :if       => :vlan_manager?
    # TODO: vlan range format validation
    # TODO: determine whether this is a true range or a single value

    module ExternalInterfaceName
      HUMAN       = N_('External interface connected to')
      HUMAN_AFTER = N_('(interface) (i.e. eth1)')
    end
    validates :external_interface_name, presence: true
    # TODO: interface name format validation

    module PublicFloatingRange
      HUMAN = N_('Floating IP range for external network ("10.0.0.0/24", for example):')
    end
    validates :public_floating_range, presence: true
    # TODO: interface format validation

    module ComputeTenantInterface
      HUMAN       = N_('Which interface to use for tenant networks:')
      HUMAN_AFTER = N_('(i.e. eth0, em1, etc.)')
    end
    validates :compute_tenant_interface,
              :presence => true
    # TODO: interface name format validation

    module PrivateFixedRange
      HUMAN = N_('Private IP range for tenant networks ("10.0.0.0/24", for example):')
    end
    validates :private_fixed_range, presence: true
    # TODO: interface format validation

    def set_defaults
      self.network_manager = NetworkManager::FLAT_DHCP
    end

    def active?
      deployment.networking == Deployment::Networking::NOVA
    end

    def vlan_manager?
      self.network_manager == NetworkManager::VLAN
    end

    def network_overrides
      { 'force_dhcp_release' => false }.tap do |h|
        h.update 'vlan_start' => self.vlan_range.split(':')[0] if self.vlan_manager?
      end

    end

  end
end
