module Staypuft
  module Concerns
    module NicFencingExtensions
      extend ActiveSupport::Concern

      included do
        attr_accessible :attrs
      end

      def fencing_enabled?
        attrs['fencing_enabled'] == '1'
      end

      def expose_lanplus?
        attrs['fence_ipmilan_expose_lanplus'] == '1'
      end

    end
  end
end

class ::Host::Managed::Jail < Safemode::Jail
  allow :bmc_nic
end

class ::Nic::Base::Jail < Safemode::Jail
  allow :fencing_enabled?, :attrs, :username, :password, :expose_lanplus?
end
