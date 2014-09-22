module Staypuft
  module Concerns
    module HostFencingExtensions
      extend ActiveSupport::Concern

      FENCING_TYPES = {
        'fence_ipmilan' => 'IPMI'
      }

      included do
        define_method :fencing do
          instance_variable_get(:@fencing_config) or
            instance_variable_set(:@fencing_config, ::Staypuft::Host::Fencing.new(self))
        end
      end
    end
  end
end

class ::Host::Managed::Jail < Safemode::Jail
  allow :bmc_nic
end
