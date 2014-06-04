module Staypuft
  class DeploymentParamImporter
    def initialize(deployment)
      @deployment = deployment
    end

    def import(in_hash)
      hostgroups = {}
      puppetclasses = {}
      deployment_node = in_hash['deployment']
      unless deployment_node.nil? || (services = deployment_node['services']).nil?
        services.each do |service_hash|
          handle_service(service_hash, hostgroups, puppetclasses)
        end
      end
    end

    def handle_service(service_hash, hostgroups, puppetclasses)
      unless (service_params = service_hash['params']).nil?
        service_params.each do |param_hash|
          handle_param(param_hash, hostgroups, puppetclasses)
        end
      end
    end

    def handle_param(param_hash, hostgroups, puppetclasses)
      hostgroup = hostgroups[param_hash['role']]
      if hostgroup.nil?
        drh = DeploymentRoleHostgroup.includes(:hostgroup, :role).
          where(:deployment_id => @deployment.id,
                "staypuft_roles.name" => param_hash['role']).first
        hostgroup = drh.hostgroup unless drh.nil?
      end
      puppetclass = (puppetclasses[param_hash['puppetclass']] ||=
                     Puppetclass.where(:name => param_hash['puppetclass']).first)
      key = param_hash['key']
      value = param_hash['value']
      # skip if either hostgroup or puppetclass are nil
      unless hostgroup.nil? || puppetclass.nil? || key.nil? || value.nil?
        hostgroup.set_param_value_if_changed(puppetclass,
                                             key,
                                             value)
      end
    end
  end
end
