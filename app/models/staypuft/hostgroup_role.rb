module Staypuft
  class HostgroupRole < ActiveRecord::Base
    attr_accessible :role, :role_id, :hostgroup, :hostgroup_id

    belongs_to :role
    belongs_to :hostgroup

    validates :role, :presence => true
    validates :hostgroup, :presence => true, :uniqueness => true

  end
end
