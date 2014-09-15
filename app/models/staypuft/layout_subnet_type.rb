module Staypuft
  class LayoutSubnetType < ActiveRecord::Base
    attr_accessible :layout_id, :layout, :subnet_type_id, :subnet_type

    belongs_to :layout
    belongs_to :subnet_type

    validates :layout, :presence => true
    validates :subnet_type, :presence => true
    validates :layout_id, :uniqueness => { :scope => :subnet_type_id }
  end
end
