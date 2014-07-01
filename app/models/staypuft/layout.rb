module Staypuft
  class Layout < ActiveRecord::Base
    has_many :deployments, :dependent => :destroy

    has_many :layout_roles, :dependent => :destroy, :order => "staypuft_layout_roles.deploy_order ASC"
    has_many :roles, :through => :layout_roles, :order => "staypuft_layout_roles.deploy_order ASC"

    has_many :layout_subnet_types
    has_many :subnet_types, :through => :layout_subnet_types

    attr_accessible :description, :name, :networking

    validates  :name, :presence => true, :uniqueness =>  {:scope => :networking}
    validates :networking, :presence => true, :inclusion => {:in =>['nova', 'neutron']}
  end
end
