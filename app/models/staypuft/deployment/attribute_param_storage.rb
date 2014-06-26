module Staypuft
  module Deployment::AttributeParamStorage
    def param_scope
      raise NotImplementedError
    end

    def param_attr(*names)
      names.each do |name|
        ivar_name  = :"@#{name}"
        param_name = "ui::#{param_scope}::#{name}"

        define_method name do
          instance_variable_get(ivar_name) or
              instance_variable_set(ivar_name,
                                    hostgroup.group_parameters.find_by_name(param_name).try(:value))
        end

        define_method "#{name}=" do |value|
          instance_variable_set(ivar_name, value)
        end

        after_save do
          value = send(name)
          if value.blank?
            hostgroup.
                group_parameters.
                find_by_name(param_name).try(:destroy)
          else
            param = hostgroup.
                group_parameters.
                find_or_initialize_by_name(param_name)
            param.update_attributes!(value: value)
          end
        end
      end
    end
  end
end

