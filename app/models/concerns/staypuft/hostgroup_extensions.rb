module Staypuft::HostgroupExtensions
  extend ActiveSupport::Concern

  included do
    has_one :deployment_hostgroup, :dependent => :destroy, :class_name => 'Staypuft::DeploymentHostgroup'
    has_one :deployment, :through => :deployment_hostgroup, :class_name => 'Staypuft::Deployment'

    has_one :hostgroup_role, :dependent => :destroy, :class_name => 'Staypuft::HostgroupRole'
    has_one :role, :through => :hostgroup_role, :class_name => 'Staypuft::Role'

  end
end
