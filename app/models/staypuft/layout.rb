module Staypuft
  class Layout < ActiveRecord::Base
    has_many :deployments, :dependent => :destroy 

    has_many :layout_roles, :dependent => :destroy
    has_many :roles, :through => :layout_roles

    attr_accessible :description, :name

    validates  :name, :presence => true, :uniqueness => true

  end
end
