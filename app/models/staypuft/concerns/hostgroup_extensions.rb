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
