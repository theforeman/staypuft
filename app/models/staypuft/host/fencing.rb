module Staypuft
  module Host
    class Fencing
      include ActiveModel::Validations

      FENCING_ATTRS = {
        'general' => ['fencing_enabled',
                      'fencing_type'],
        'fence_ipmilan' => ['fence_ipmilan_address',
                            'fence_ipmilan_username',
                            'fence_ipmilan_password',
                            'fence_ipmilan_expose_lanplus',
                            'fence_ipmilan_lanplus_options']
      }

      validates :fencing_type, :presence => true, :if => Proc.new { |f|
        f.fencing_enabled == '1' &&
          @host.interfaces.any?{ |nic| nic.type == 'Nic::BMC' && !nic.marked_for_destruction? }
      }

      def initialize(host)
        @host = host
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

      def update(values)
        values.each do |key, value|
          instance_var_name  = :"@#{key}"
          instance_variable_set(instance_var_name, value)
        end

        bmc_nics = @host.interfaces.select{ |interface| interface.type == "Nic::BMC" }
        return if bmc_nics.empty?

        bmc_nic = bmc_nics[0]
        bmc_nic.attrs.merge!(values)
        bmc_nic.save
      end

      # compatibility with validates_associated
      def marked_for_destruction?
        false
      end
    end
  end
end