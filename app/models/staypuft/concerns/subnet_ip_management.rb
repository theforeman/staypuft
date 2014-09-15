module Staypuft
  module Concerns
    module SubnetIpManagement
      extend ActiveSupport::Concern

      included do
        before_save :reserve_ip
      end

      def reserve_ip
        if self.identifier =~ /\Avip\d+\Z/ && self.subnet.present? && self.subnet.ipam?
          self.ip ||= self.subnet.unused_ip
        end
      end
    end
  end
end
