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
    end
  end
end
