module Staypuft
  class SubnetType < ActiveRecord::Base
    PXE = 'PXE'

    validates :name, :presence => true

    has_many :layout_subnet_types, :dependent => :destroy
    has_many :layouts, :through => :layout_subnet_types

    attr_accessible :name

    has_many :subnet_typings
    has_many :subnets, :through => :subnet_typings
  end
end
