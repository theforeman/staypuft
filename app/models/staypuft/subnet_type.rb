module Staypuft
  class SubnetType < ActiveRecord::Base
    validates :name, :presence => true

    has_many :layout_subnet_types
    has_many :layouts, :through => :layout_subnet_types

    attr_accessible :name
  end
end
