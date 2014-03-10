module Staypuft
  class Service < ActiveRecord::Base
    has_many :role_services, :dependent => :destroy
    has_many :roles, :through => :role_services

    #has_many :service_classes, :dependent => :destroy
    #has_many :puppetclasses, :through => :service_classes

    attr_accessible :description, :name

    validates  :name, :presence => true, :uniqueness => true
  end
end
