module Staypuft
  class Deployment < ActiveRecord::Base
    belongs_to :layout
    attr_accessible :description, :name, :layout_id, :layout

    #has_many :host_group_deployments
    #has_many :host_groups, :through => :host_group_deployments

    validates  :name, :presence => true, :uniqueness => true

    validates :layout, :presence => true
  end
end
