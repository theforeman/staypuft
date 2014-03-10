module Staypuft
  class RoleService < ActiveRecord::Base
    attr_accessible :service, :service_id, :role, :role_id

    belongs_to :service
    belongs_to :role

    validates :service, :presence => true
    validates :role, :presence => true, :uniqueness => {:scope => :service}

  end
end
