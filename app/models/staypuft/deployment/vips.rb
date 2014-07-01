module Staypuft
  class Deployment::VIPS < Deployment::AbstractParamScope

    VIP_NAMES = [:ceilometer, :cinder, :db, :glance, :heat, :horizon, :keystone, :loadbalancer,
                 :nova, :neutron, :qpid, :swift]
    COUNT     = VIP_NAMES.size

    def self.param_scope
      'vips'
    end

    param_attr :user_range

    HUMAN = N_('Virtual IP addresses range')

    def range
      (user_range || default_range)
      # TODO reserve the IP addresses
    end

    # TODO validate range that it is array with size 11 and that it contains only IPS

    def default_range
      @default_range ||= begin
        top_ip = hostgroup.subnet.to.split('.').map &:to_i
        ((top_ip[-1]-(COUNT-1))..top_ip[-1]).
            map { |last| [*top_ip[0..2], last] }.
            map { |ip| ip.join '.' }
      end
    end

    def get(name)
      range[VIP_NAMES.index(name) || raise(ArgumentError, "unknown #{name}")]
    end
  end
end
