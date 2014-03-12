module Staypuft
  class ServiceClass < ActiveRecord::Base
    attr_accessible :service_id, :service, :puppetclass_id, :puppetclass

    belongs_to :service
    belongs_to :puppetclass

    validates :service_id, :presence => true
    validates :puppetclass_id, :presence => true, :uniqueness => {:scope => :service_id}

  end
end
