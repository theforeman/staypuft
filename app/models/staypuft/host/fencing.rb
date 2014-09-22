module Staypuft
  module Host
    class Fencing

      FENCING_ATTRS = {
        'general' => ['fencing_enabled',
                      'fencing_type'],
        'fence_ipmilan' => ['fence_ipmilan_address',
                            'fence_ipmilan_username',
                            'fence_ipmilan_password',
                            'fence_ipmilan_expose_lanplus',
                            'fence_ipmilan_lanplus_options']
      }

      def initialize(host)
        FENCING_ATTRS.each do |key, attrs|
          attrs.each do |name|
            instance_var_name  = :"@#{name}"
            value = host.bmc_nic.attrs[name] if host.bmc_nic && host.bmc_nic.attrs.has_key?(name)
            self.class.send(:define_method, name) do
              instance_variable_get(instance_var_name) or
                instance_variable_set(instance_var_name, value)
            end
          end
        end
      end

    end
  end
end