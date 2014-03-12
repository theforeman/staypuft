module Staypuft
  class Deployment < ActiveRecord::Base
    belongs_to :layout
    attr_accessible :description, :name, :layout_id, :layout

    has_many :deployment_hostgroups, :dependent => :destroy
    has_many :hostgroups, :through => :deployment_hostgroups

    validates  :name, :presence => true, :uniqueness => true

    validates :layout, :presence => true
  end
end
