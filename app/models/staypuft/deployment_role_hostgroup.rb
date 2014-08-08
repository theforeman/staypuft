module Staypuft
  class DeploymentRoleHostgroup < ActiveRecord::Base
    attr_accessible :deployment, :deployment_id, :hostgroup, :hostgroup_id, :role, :role_id, :deploy_order

    belongs_to :deployment
    belongs_to :hostgroup, dependent: :destroy
    belongs_to :role
    has_many :services, :through => :role

    validates :deployment, :presence => true
    validates :role, :presence => true
    validates :role_id, :uniqueness => {:scope => :deployment_id}
    validates :hostgroup, :presence => true
    validates :hostgroup_id, :uniqueness => true
    has_many :hosts, :through => :hostgroup

    validates  :deploy_order, :presence => true

    before_destroy :prepare_destroy

    def prepare_destroy
      hosts.each &:open_stack_unassign
    end

  end
end
