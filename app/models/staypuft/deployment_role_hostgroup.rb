module Staypuft
  class DeploymentRoleHostgroup < ActiveRecord::Base
    attr_accessible :deployment, :deployment_id, :hostgroup, :hostgroup_id

    belongs_to :deployment
    belongs_to :hostgroup

    validates :deployment, :presence => true
    validates :hostgroup, :presence => true
    validates :hostgroup_id, :uniqueness => true

  end
end
