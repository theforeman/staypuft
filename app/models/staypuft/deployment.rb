module Staypuft
  class Deployment < ActiveRecord::Base
    attr_accessible :description, :name, :layout_id, :layout

    belongs_to :layout
    belongs_to :hostgroup

    has_many :deployment_role_hostgroups, :dependent => :destroy
    has_many :child_hostgroups, :through => :deployment_role_hostgroups, :class_name => 'Hostgroup'
    has_many :roles, :through => :child_hostgroups

    validates  :name, :presence => true, :uniqueness => true

    validates :layout, :presence => true

    scoped_search :on => :name, :complete_value => :true
  end
end
