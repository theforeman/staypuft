module Staypuft
  class ServiceClass < ActiveRecord::Base
    attr_accessible :service_id, :service, :puppetclass_id, :puppetclass

    belongs_to :service
    belongs_to :puppetclass

    validates :service, :presence => true
    validates :puppetclass, :presence => true
    validates :puppetclass_id, :uniqueness => {:scope => :service_id}

  end
end
