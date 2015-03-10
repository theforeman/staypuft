module Staypuft
  module Concerns
    module NicBondingExtensions
      extend ActiveSupport::Concern

      included do
        before_save :ensure_mac
      end

      def ensure_mac
        mac_addresses = self.host.interfaces.where(
            :identifier => attached_devices_identifiers).pluck(:mac).compact
        self.mac =  mac_addresses.first unless mac_addresses.include?(self.mac)
      end
    end
  end
end
