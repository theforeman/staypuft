module Staypuft
  class HostsController < ::HostsController

    before_filter :set_fencing_params, only: 'update'

    private
    def set_fencing_params
      fencing_params = params['host'].delete('fencing')

      if fencing_params['attrs']['fencing_enabled'] == '1'
        host_attrs = params['host']['interfaces_attributes'].values.find{|host_attrs| host_attrs['provider'] == 'IPMI'}
        host_attrs.merge!(fencing_params)
      end
    end

  end
end
