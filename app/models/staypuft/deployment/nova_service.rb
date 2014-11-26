module Staypuft
  class Deployment::NovaService < Deployment::AbstractParamScope
    def self.param_scope
      'nova'
    end

    VLAN_HELP         = Deployment::NeutronService::VLAN_HELP

    param_attr :network_manager, :vlan_range, :public_floating_range, :private_fixed_range,
               :network_device_mtu

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
        unless record.private_fixed_range.empty?
          if record.network_size < 4
            record.errors[:private_fixed_range] << "Fixed range is too small. Specify CIDR for network size #{record.min_fixed_range_cidr} or larger"
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

    module PublicFloatingRange
      HUMAN       = N_('Floating IP range for external network')
      HUMAN_AFTER = N_('(e.g. "10.0.0.0/24")')
    end

    validates :public_floating_range, presence: true

    module PrivateFixedRange
      HUMAN       = N_('Fixed IP range for tenant networks')
      HUMAN_AFTER = PublicFloatingRange::HUMAN_AFTER
    end

    validates :private_fixed_range, presence: true

    module Mtu
      HUMAN       = Staypuft::Deployment::NeutronService::Mtu::HUMAN
      HUMAN_AFTER = Staypuft::Deployment::NeutronService::Mtu::HUMAN_AFTER
    end

    validates :network_device_mtu, numericality: { only_integer: true }, allow_blank: true

    def set_defaults
      self.network_manager = NetworkManager::FLAT_DHCP
      self.network_device_mtu = nil
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

    def fixed_range_size
      fixed_range_str = private_fixed_range
      if fixed_range_str.empty?
        0
      else
        fixed_range = IPAddr.new(fixed_range_str).to_range
        fixed_range.last.to_i - fixed_range.first.to_i + 1
      end
    end

    # network size is equal to the number of IP addresses in
    # the fixed range, divided by the number of networks,
    # rounded *down* to the next power of two (or zero if <1)
    def network_size
      unrounded_size = fixed_range_size / num_networks
      if unrounded_size < 1
        0
      else
        2**Math.log(unrounded_size,2).floor
      end
    end

    # for the current num_networks value (1 for non-vlan;
    # based on the vlan range for VLAN, this calculates
    # the smallest fixed range network cidr assuming the
    # smallest useful network size of 4 (2 hosts+network
    # address+broadcast address)
    def min_fixed_range_cidr
      "/#{32 - Math.log(4*num_networks,2).ceil}"
    end

    def param_hash
      { 'network_manager'          => network_manager,
        'vlan_range'               => vlan_range,
        'public_floating_range'    => public_floating_range,
        'private_fixed_range'      => private_fixed_range }
    end

    class Jail < Safemode::Jail
      allow :network_manager, :network_overrides, :private_fixed_range, :public_floating_range,
        :num_networks, :network_size, :network_device_mtu
    end

  end
end
