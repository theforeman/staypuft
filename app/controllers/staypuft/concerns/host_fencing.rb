module Staypuft
  module Concerns
    module HostFencing

      extend ActiveSupport::Concern

      included do
        before_filter :set_fencing_params, only: 'update'
      end

      private
      def set_fencing_params
        fencing_params = params['host'].delete('fencing')
        if fencing_params['fencing_enabled'] == '1' || @host.bmc_nic
          nic_params = params['host']['interfaces_attributes'].values.find{|host_attrs| host_attrs['provider'] == 'IPMI'}
          if nic_params.has_key?('attrs')
            nic_params['attrs'].merge!(fencing_params)
          else
            nic_params['attrs'] = fencing_params
          end
        end
      end

    end
  end
end
