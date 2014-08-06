module Staypuft
  class Deployment::NovaService < Deployment::AbstractParamScope
    def self.param_scope
      'nova'
    end

    INTERFACE_HELP    = Deployment::NeutronService::INTERFACE_HELP
    VLAN_HELP         = Deployment::NeutronService::VLAN_HELP

    param_attr :network_manager, :vlan_range, :external_interface_name, :public_floating_range,
               :compute_tenant_interface, :private_fixed_range

    class NetworkRangesValidator < ActiveModel::Validator
      def validate(record)
        valid_ranges = []
        [:public_floating_range, :private_fixed_range].each do |range_param|
          begin
            unless (range_str = record.send(range_param)).empty?
              ip_addr = IPAddr.new(range_str)
              ip_range = ip_addr.to_range
              if ip_range.begin == ip_range.end
                record.errors[range_param] << "Specify address range, not single value"
              else
                valid_ranges << [range_param, ip_addr]
              end
            end
          rescue
            record.errors[range_param] << "Invalid Network Range Format"
          end
          # don't validate conflicts unless both ranges otherwise passed validation
          if valid_ranges.size == 2
            valid_ranges.each_with_index do |param_and_ip, index|
              this_param_name = param_and_ip[0]
              this_ip_range = param_and_ip[1].to_range

              other_param_name = valid_ranges[(index+1)%2][0]
              other_ip_addr = valid_ranges[(index+1)%2][1]
              ["begin", "end"].each do |action|
                if (other_ip_addr===this_ip_range.send(action))
                  record.errors[this_param_name] << "Range #{action} #{this_ip_range.begin} overlaps with range for #{other_param_name.to_s.humanize}"
                end
              end
            end
          end
        end
      end
    end

    validates_with NetworkRangesValidator

    module NetworkManager
      FLAT_DHCP = 'FlatDHCPManager'
      VLAN      = 'VlanManager'
      LABELS    = { FLAT_DHCP => N_('Flat with DHCP'),
                    VLAN      => N_('VLAN') }
      TYPES     = LABELS.keys
      HUMAN     = N_('Tenant Network Type')
    end

    validates :network_manager, presence: true, inclusion: { in: NetworkManager::TYPES }

    module VlanRange
      HUMAN       = N_('VLAN Range')
      HUMAN_AFTER = VLAN_HELP
    end

    class NovaVlanRangeValidator < ActiveModel::EachValidator
      include Staypuft::Deployment::VlanRangeValuesValidator
    end

    validates :vlan_range,
              :presence        => true,
              :if              => :vlan_manager?,
              :nova_vlan_range => true

    module ExternalInterfaceName
      HUMAN       = N_('Which interface to use for external networks')
      HUMAN_AFTER = INTERFACE_HELP
    end

    validates :external_interface_name, presence: true
    # TODO: interface name format validation

    module PublicFloatingRange
      HUMAN       = N_('Floating IP range for external network')
      HUMAN_AFTER = N_('(e.g. "10.0.0.0/24")')
    end

    validates :public_floating_range, presence: true
    # TODO: interface format validation

    module ComputeTenantInterface
      HUMAN       = N_('Which interface to use for tenant networks')
      HUMAN_AFTER = INTERFACE_HELP
    end

    validates :compute_tenant_interface,
              :presence => true
    # TODO: interface name format validation

    module PrivateFixedRange
      HUMAN       = N_('Private IP range for tenant networks')
      HUMAN_AFTER = PublicFloatingRange::HUMAN_AFTER
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
        h.update 'vlan_start' => vlan_start if self.vlan_manager?
      end.to_yaml
    end

    def vlan_range_arr
      arr = self.vlan_range.split(':')
    end

    def vlan_start
      vlan_range_arr[0]
    end

    def num_networks
      if self.vlan_manager?
        vlan_range_arr[1].to_i - vlan_range_arr[0].to_i + 1
      else
        1
      end
    end

    def private_iface
      compute_tenant_interface.downcase unless compute_tenant_interface.nil?
    end

    def public_iface
      external_interface_name.downcase unless external_interface_name.nil?
    end

    def param_hash
      { 'network_manager'          => network_manager,
        'vlan_range'               => vlan_range,
        'external_interface_name'  => external_interface_name,
        'public_floating_range'    => public_floating_range,
        'compute_tenant_interface' => compute_tenant_interface,
        'private_fixed_range'      => private_fixed_range }
    end

    class Jail < Safemode::Jail
      allow :network_manager, :network_overrides, :private_fixed_range, :public_floating_range,
        :private_iface, :public_iface, :num_networks
    end

  end
end
