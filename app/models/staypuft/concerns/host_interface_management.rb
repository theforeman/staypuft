module Staypuft
  module Concerns
    module HostInterfaceManagement
      extend ActiveSupport::Concern

      included do

      end

      def clean_vlan_interfaces
        self.interfaces.virtual.map(&:destroy)
      end
    end
  end
end
