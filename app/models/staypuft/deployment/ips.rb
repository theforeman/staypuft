module Staypuft
  class Deployment::IPS < Deployment::AbstractParamScope

    class Jail < Safemode::Jail
      allow :controller_ip, :controller_ips, :controller_fqdns
    end

    def controllers
      @controllers ||= deployment.controller_hostgroup.hosts.order(:id)
    end

    # FIXME: check for any invocation without subnet type param
    def controller_ips(subnet_type_name)
      controllers.map { |controller| deployment.network_query.ip_for_host(controller, subnet_type_name) }
    end

    def controller_fqdns
      controllers.map &:fqdn
    end

    # FIXME: check for any invocation without subnet type param
    def controller_ip(subnet_type_name)
      deployment.network_query.ip_for_host(controllers.tap { |v| v.size == 1 or raise }.first, subnet_type_name)
    end

  end
end
