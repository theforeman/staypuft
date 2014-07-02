module Staypuft
  class Deployment::IPS < Deployment::AbstractParamScope

    def controllers
      @controllers ||= Hostgroup.
          includes(:deployment_role_hostgroup).
          where(DeploymentRoleHostgroup.table_name => { deployment_id: deployment,
                                                        role_id:       Staypuft::Role.controller }).
          first.
          hosts
    end

    def controller_ips
      controllers.map &:ip
    end

    def controller_fqdns
      controllers.map &:fqdn
    end

    def controller_ip
      controllers.tap { |v| v.size == 1 or raise }.first.ip
    end

  end
end
