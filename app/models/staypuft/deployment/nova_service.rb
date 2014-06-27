module Staypuft
  class Deployment::NovaService < Deployment::AbstractParamScope
    def self.param_scope
      'nova'
    end

    param_attr :network_manager, :vlan_range, :use_external_interface,
        :external_interface_name, :compute_tenant_interface

    module NetworkManager
      FLAT_DHCP = 'FlatDHCPManager'
      FLAT      = 'FlatManager'
      VLAN      = 'VlanManager'
      LABELS    = { FLAT_DHCP => N_('FlatDHCP'),
                    FLAT      => N_('Flat'),
                    VLAN      => N_('VLAN') }
      TYPES     = LABELS.keys
      HUMAN  = N_('Network Type')
    end
    validates :network_manager, presence: true, inclusion: { in: NetworkManager::TYPES }

    module VlanRange
      HUMAN        = N_('VLAN Range')
      HUMAN_AFTER  = '[0-4094]'
    end
    validates :vlan_range,
              :presence     => true,
              :if           => :vlan_manager?
    # TODO: vlan range format validation

    module UseExternalInterface
      HUMAN        = N_('Configure external interface on network node')
    end
    validates :use_external_interface, inclusion: { in: [true, false] }

    module ExternalInterfaceName
      HUMAN        = N_('External interface connected to')
      HUMAN_AFTER  = N_('(interface) (i.e. eth1)')
    end
    validates :external_interface_name,
              :presence     => true,
              :if           => :use_external_interface
    # TODO: interface name format validation

    module ComputeTenantInterface
      HUMAN        = N_('Which interface to use for tenant networks:')
      HUMAN_AFTER  = N_('(i.e. eth0, em1, etc.)')
    end
    validates :compute_tenant_interface,
              :presence     => true
    # TODO: interface name format validation

    def set_defaults
      self.network_manager = NetworkManager::FLAT_DHCP
    end

    def active?
      deployment.networking == Deployment::Networking::NOVA
    end

    def vlan_manager?
      self.network_manager == NetworkManager::VLAN
    end

  end
end
