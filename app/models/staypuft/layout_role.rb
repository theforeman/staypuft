module Staypuft
  class LayoutRole < ActiveRecord::Base
    attr_accessible :layout, :layout_id, :role, :role_id, :deploy_order

    belongs_to :layout
    belongs_to :role

    validates :layout, :presence => true
    validates :role, :presence => true
    validates :role_id, :uniqueness => {:scope => :layout_id}
    validates  :deploy_order, :presence => true

  end
end
