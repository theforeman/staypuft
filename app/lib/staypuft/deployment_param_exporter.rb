module Staypuft
  class DeploymentParamExporter

    NAME = :name
    DESCRIPTION = :description
    UI_PARAMS = "ui_params"

    PUPPET_PARAMS  = "puppet_params"
    SERVICES       = "services"
    SERVICE_NAME   = "name"
    SERVICE_PARAMS = "params"

    PARAM_KEY         = "key"
    PARAM_ROLE        = "role"
    PARAM_PUPPETCLASS = "puppetclass"
    PARAM_VALUE       = "value"
    def initialize(deployment)
      @deployment = deployment
    end

    def to_hash
      {"deployment" => {NAME.to_s          => @deployment.send(NAME),
                        DESCRIPTION.to_s   => @deployment.send(DESCRIPTION),
                        UI_PARAMS          => ui_params,
                        PUPPET_PARAMS      => puppet_params} }
    end

    def ui_params
      param_hash = {}
      services_hash = {}
      Deployment::EXPORT_PARAMS.each {|param| param_hash[param.to_s] = @deployment.send(param)}
      Deployment::EXPORT_SERVICES.each {|param| services_hash[param.to_s] = @deployment.send(param).param_hash}
      param_hash[SERVICES.to_s] = services_hash
      param_hash
    end

    def puppet_params
      { SERVICES => services }
    end

    def services
      @deployment.services_hostgroup_map.map { |one_service, hostgroup| service(one_service, hostgroup) }
    end

    def service(one_service, hostgroup)
      { SERVICE_NAME => one_service.name, SERVICE_PARAMS => params(one_service, hostgroup) }
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

      { PARAM_KEY         => param_hash[:param_key].key,
        PARAM_ROLE        => param_hash[:role].name,
        PARAM_PUPPETCLASS => param_hash[:puppetclass].name,
        PARAM_VALUE       => value }
    end

  end
end
