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
          # FIXME: not sure if hard-coding false is correct here, but without it, false was
          # being set to 'nil', breaking boolean values (empty arrays may prove to be a similar problem)
          if value.blank? && !(value == false)
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

