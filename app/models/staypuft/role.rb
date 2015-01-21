module Staypuft
  class Role < ActiveRecord::Base
    # until we have puppetssh, "run puppet" below means "provision and run puppet"

    # run puppet on all nodes concurrently
    ORCHESTRATION_CONCURRENT = "concurrent"
    # run puppet on one node at a time
    ORCHESTRATION_SERIAL     = "serial"
    # run puppet on the first mode, then the rest concurrently
    ORCHESTRATION_LEADER     = "leader"

    ORCHESTRATION_MODES = [ORCHESTRATION_CONCURRENT, ORCHESTRATION_SERIAL, ORCHESTRATION_LEADER]

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

    validates :orchestration, :inclusion => {:in => ORCHESTRATION_MODES }

    scope(:in_deployment, lambda do |deployment|
      joins(:deployment_role_hostgroups).
          where(DeploymentRoleHostgroup.table_name => { deployment_id: deployment })
    end)

    scope(:controller, where(name: Seeder::CONTROLLER_ROLES.map { |h| h.fetch(:name) }))

    scope(:cephosd, where(name: Seeder::CEPH_ROLES.map { |h| h.fetch(:name) }))

    scope(:compute, where(name: Seeder::COMPUTE_ROLES.map { |h| h.fetch(:name) }))
  end
end
