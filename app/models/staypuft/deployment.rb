module Staypuft
  class Deployment < ActiveRecord::Base
    attr_accessible :description, :name, :layout_id, :layout

    belongs_to :layout
    belongs_to :hostgroup, :dependent => :destroy

    has_many :deployment_role_hostgroups, :dependent => :destroy
    has_many :child_hostgroups, :through => :deployment_role_hostgroups, :class_name => 'Hostgroup', :source => :hostgroup
    has_many :roles, :through => :child_hostgroups

    validates  :name, :presence => true, :uniqueness => true

    validates :layout, :presence => true

    scoped_search :on => :name, :complete_value => :true

    def destroy
      child_hostgroups.each do |h|
        h.destroy
      end
      #do the main destroy
      super
    end

  end
end
