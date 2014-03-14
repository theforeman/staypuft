module Staypuft::HostgroupExtensions
  extend ActiveSupport::Concern

  included do
    has_one :deployment_role_hostgroup, :dependent => :destroy, :class_name => 'Staypuft::DeploymentRoleHostgroup'
    has_one :parent_deployment, :through => :deployment_role_hostgroup, :class_name => 'Staypuft::Deployment'

    has_one :deployment, :class_name => 'Staypuft::Deployment'

    has_one :hostgroup_role, :dependent => :destroy, :class_name => 'Staypuft::HostgroupRole'
    has_one :role, :through => :hostgroup_role, :class_name => 'Staypuft::Role'

  end
end
