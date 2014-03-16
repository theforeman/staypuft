module Staypuft
  class RoleClass < ActiveRecord::Base
    attr_accessible :role_id, :role, :puppetclass_id, :puppetclass

    belongs_to :role
    belongs_to :puppetclass

    validates :role, :presence => true
    validates :puppetclass, :presence => true
    validates :puppetclass_id, :uniqueness => {:scope => :role_id}
  end
end
