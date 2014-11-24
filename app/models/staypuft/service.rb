module Staypuft
  class Service < ActiveRecord::Base
    has_many :role_services, :dependent => :destroy
    has_many :roles, :through => :role_services
    has_many :hostgroups, :through => :roles

    has_many :service_classes, :dependent => :destroy
    has_many :puppetclasses, :through => :service_classes

    attr_accessible :description, :name

    validates :name, :presence => true, :uniqueness => true

    def ui_params_for_form(hostgroup)
      return [] if (hostgroup.nil?)
      role = hostgroup.role
      self.puppetclasses.collect do |pclass|
        pclass.class_params.collect do |class_param|
          { :hostgroup => hostgroup,
            :role => role,
            :puppetclass => pclass,
            :param_key => class_param }
        end
      end.flatten
    end
  end
end
