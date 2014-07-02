module Staypuft
  class Role < ActiveRecord::Base
    has_many :layout_roles, :dependent => :destroy
    has_many :layouts, :through => :layout_roles

    has_many :role_classes, :dependent => :destroy
    has_many :puppetclasses, :through => :role_classes

    has_many :deployment_role_hostgroups, :dependent => :destroy
    has_many :hostgroups, :through => :deployment_role_hostgroups
    has_many :deployments, :through => :deployment_role_hostgroups

    has_many :role_services, :dependent => :destroy
    has_many :services, :through => :role_services

    attr_accessible :description, :max_hosts, :min_hosts, :name

    validates :name, :presence => true, :uniqueness => true

    scope(:in_deployment, lambda do |deployment|
      joins(:deployment_role_hostgroups).
          where(DeploymentRoleHostgroup.table_name => { deployment_id: deployment })
    end)

    scope(:controller, where(name: Seeder::CONTROLLER_ROLES.map { |h| h.fetch(:name) }))
  end
end
