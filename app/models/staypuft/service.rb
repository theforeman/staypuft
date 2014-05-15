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
      if hostgroup.puppetclasses.blank?
        params_from_hash = []
      else
        puppetclass      = hostgroup.puppetclasses.first
        params_from_hash = UI_PARAMS.fetch(self.name, []).collect do |param_key|
          if param_key.is_a?(Array)
            param_name        = param_key[0]
            param_puppetclass = Puppetclass.find_by_name(param_key[1])
          else
            param_name        = param_key
            param_puppetclass = puppetclass
          end
          param_lookup_key = param_puppetclass.class_params.where(:key => param_key).first
          param_lookup_key.nil? ? nil : { :hostgroup   => hostgroup,
                                          :role        => role,
                                          :puppetclass => param_puppetclass,
                                          :param_key   => param_lookup_key }
        end.compact
      end
      params_from_service = self.puppetclasses.collect do |pclass|
        pclass.class_params.collect do |class_param|
          { :hostgroup => hostgroup,
            :role => role,
            :puppetclass => pclass,
            :param_key => class_param }
        end
      end.flatten
      params_from_hash + params_from_service
    end
  end
end
