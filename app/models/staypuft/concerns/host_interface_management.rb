module Staypuft
  module Concerns
    module HostInterfaceManagement
      extend ActiveSupport::Concern

      included do

      end

      def clean_vlan_interfaces
        self.interfaces.virtual.map(&:destroy)
      end

      def interfaces_identifiers
        interfaces = [ self.primary_interface ]
        interfaces += self.respond_to?(:interfaces) ? self.interfaces.where("type <> 'Nic::BMC'").physical.map(&:identifier) : []
        interfaces
      end

      def make_all_interfaces_managed
        self.interfaces.each do |interface|
          interface.managed = true
          interface.save!
        end
      end

      def network_query
        @network_query || NetworkQuery.new(self.hostgroup.deployment, self)
      end

      def primary_interface_is_bonded?
        self.bond_interfaces.any? do |bond|
          bond.attached_devices_identifiers.any? do |interface_identifier|
            self.has_primary_interface? ? self.primary_interface == interface_identifier : false
          end
        end
      end
    end
  end
end

class ::Host::Managed::Jail < Safemode::Jail
  allow :network_query, :primary_interface_is_bonded?
end
