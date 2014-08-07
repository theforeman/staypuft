require 'resolv'

module Staypuft
  class Deployment::IPS < Deployment::AbstractParamScope

    class Jail < Safemode::Jail
      allow :controller_ip, :controller_ips, :controller_fqdns
    end

    def controllers
      @controllers ||= deployment.controller_hostgroup.hosts.order(:id)
    end

    def controller_ips
      controllers.map do |controller|
        ip_for_controller(controller)
      end
    end

    def controller_fqdns
      controllers.map &:fqdn
    end

    def controller_ip
      ip_for_controller(controllers.tap { |v| v.size == 1 or raise }.first)
    end

    # TODO: a better fix is needed once we have explicit subnet support in staypuft
    # This is needed because host.ip doesn't always return the expected ip address
    # when the host has more than one network interface -- this ensures that the
    # provisioning network interface is the chosen one.
    def ip_for_controller(controller)
      Resolv::DNS.new(:nameserver => 'localhost').getaddress(controller.fqdn).to_s
    end
  end
end
