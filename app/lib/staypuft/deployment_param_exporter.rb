module Staypuft
  class DeploymentParamExporter
    def initialize(deployment)
      @deployment = deployment
    end

    def to_hash
      {"deployment" => {"name" => @deployment.name, "services" => services}}
    end

    def services
      @deployment.services_hostgroup_map.map { |one_service, hostgroup| service(one_service, hostgroup) }
    end

    def service(one_service, hostgroup)
      { 'name' => one_service.name, 'params' => params(one_service, hostgroup) }
    end

    def params(one_service, hostgroup)
      one_service.ui_params_for_form(hostgroup).map do |param_hash|
        param param_hash
      end
    end

    def param(param_hash)
      value = param_hash[:hostgroup].current_param_value_str(param_hash[:param_key])
      # force encoding needed to prevent to_yaml from outputting some strings as binary
      value.force_encoding("UTF-8") if value.is_a? String

      { 'key' => param_hash[:param_key].key,
        'role' => param_hash[:role].name,
        'puppetclass' => param_hash[:puppetclass].name,
        'value' => value }
    end

  end
end
