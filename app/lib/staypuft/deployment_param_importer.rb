module Staypuft
  class DeploymentParamImporter
    def initialize(deployment)
      @deployment = deployment
    end

    def import(in_hash)
      hostgroups = {}
      puppetclasses = {}
      if !in_hash.is_a?(Hash) || ((deployment_node = in_hash['deployment']).nil?)
        raise ArgumentError, "Invalid import file: no 'deployment' node found"
      end
      # We don't import name/description to avoid conflict with existing deployments
      if (ui_params = deployment_node[DeploymentParamExporter::UI_PARAMS])
        handle_obj_params(ui_params, @deployment, Deployment::EXPORT_PARAMS)
        if (ui_services = ui_params[DeploymentParamExporter::SERVICES])
          handle_ui_services(ui_services, @deployment,  Deployment::EXPORT_SERVICES)
        end
      end
      @deployment.save!

      handle_services(deployment_node, hostgroups, puppetclasses)
    end

    def handle_ui_services(services_node, obj, service_list)
      service_list.each do |service_name|
        if (service_node = services_node[service_name.to_s])
          service_obj = obj.send(service_name)
          handle_obj_params(service_node, service_obj, service_obj.param_hash.keys)
        end
      end
    end

    def handle_obj_params(node, obj, param_list)
      param_list.each do |param_name|
        param_value = node[param_name.to_s]
        obj.send(param_name.to_s+"=",param_value) if param_value
      end
    end

    def handle_services(deployment_node, hostgroups, puppetclasses)
      unless deployment_node.nil? || (puppet_params = deployment_node[DeploymentParamExporter::PUPPET_PARAMS]).nil?
        services = puppet_params[DeploymentParamExporter::SERVICES]
        if services
          services.each do |service_hash|
            handle_service(service_hash, hostgroups, puppetclasses)
          end
        end
      end
    end

    def handle_service(service_hash, hostgroups, puppetclasses)
      unless (service_params = service_hash[DeploymentParamExporter::SERVICE_PARAMS]).nil?
        service_params.each do |param_hash|
          handle_param(param_hash, hostgroups, puppetclasses)
        end
      end
    end

    def handle_param(param_hash, hostgroups, puppetclasses)
      hostgroup = hostgroups[param_hash[DeploymentParamExporter::PARAM_ROLE]]
      if hostgroup.nil?
        drh = DeploymentRoleHostgroup.includes(:hostgroup, :role).
          where(:deployment_id => @deployment.id,
                "staypuft_roles.name" => param_hash[DeploymentParamExporter::PARAM_ROLE]).first
        hostgroup = drh.hostgroup unless drh.nil?
      end
      puppetclass = (puppetclasses[param_hash[DeploymentParamExporter::PARAM_PUPPETCLASS]] ||=
                     Puppetclass.where(:name => param_hash[DeploymentParamExporter::PARAM_PUPPETCLASS]).first)
      key = param_hash[DeploymentParamExporter::PARAM_KEY]
      value = param_hash[DeploymentParamExporter::PARAM_VALUE]
      # skip if either hostgroup or puppetclass are nil
      unless hostgroup.nil? || puppetclass.nil? || key.nil? || value.nil?
        hostgroup.set_param_value_if_changed(puppetclass,
                                             key,
                                             value)
      end
    end
  end
end
