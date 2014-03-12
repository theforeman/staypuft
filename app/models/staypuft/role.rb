module Staypuft
  class Role < ActiveRecord::Base
    has_many :layout_roles, :dependent => :destroy
    has_many :layouts, :through => layout_roles

    has_many :role_classes, :dependent => :destroy
    has_many :puppetclasses, :through => :role_classes

    has_many :hostgroup_roles, :dependent => :destroy
    has_many :hostgroups, :through => :hostgroup_roles

    has_many :role_services, :dependent => :destroy
    has_many :services, :through => :role_services

    attr_accessible :description, :max_hosts, :min_hosts, :name

    validates  :name, :presence => true, :uniqueness => true
  end
end
