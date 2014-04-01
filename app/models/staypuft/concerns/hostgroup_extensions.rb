module Staypuft::Concerns::HostgroupExtensions
  extend ActiveSupport::Concern

  included do
    has_one :deployment_role_hostgroup, :dependent => :destroy, :class_name => 'Staypuft::DeploymentRoleHostgroup'
    has_one :parent_deployment, :through => :deployment_role_hostgroup, :class_name => 'Staypuft::Deployment'
    has_one :role, :through => :deployment_role_hostgroup, :class_name => 'Staypuft::Role'

    has_one :deployment, :class_name => 'Staypuft::Deployment'

    def add_puppetclasses_from_resource(resource)
      if resource.respond_to?(:puppetclasses)
        resource.puppetclasses.each do |puppetclass|
          unless puppetclasses.include?(puppetclass)
            puppetclasses << puppetclass
          end
        end
      end
    end

    def current_param_value(key)
      if(v = LookupValue.where(:lookup_key_id => key.id, :id => lookup_values).first)
        return v.value, to_label
      end
      return inherited_lookup_value(key)
    end

    def current_param_value_str(key)
      val = current_param_value(key)[0]
      val.is_a?(Array) ? val.join(", ") : val
    end

    def set_param_value_if_changed(puppetclass, key, value)
      lookup_key = puppetclass.class_params.where(:key=>key).first
      current_value = current_param_value(lookup_key)[0]
      new_value = current_value.is_a?(Array) ? value.split(", ") : value
      unless current_value == new_value
        lookup = LookupValue.where(:match => hostgroup.send(:lookup_value_match),
                                   :lookup_key_id => lookup_key.id).first_or_initialize
        lookup.value = new_value
        lookup.save!
      end
    end
  end

  module ClassMethods
    Gem::Version.new(SETTINGS[:version].to_s.gsub(/-develop$/, '')) < Gem::Version.new('1.5') or
        raise 'remove nest method, nesting Hostgroups is fixed in Foreman 1.5, use just parent_id'

    def nest(name, parent)
      new           = parent.dup
      new.parent_id = parent.id
      new.name      = name

      new.puppetclasses = parent.puppetclasses
      new.locations     = parent.locations
      new.organizations = parent.organizations

      # Clone any parameters as well
      new.group_parameters.each { |param| parent.group_parameters << param.dup }
      new
    end
  end

end
