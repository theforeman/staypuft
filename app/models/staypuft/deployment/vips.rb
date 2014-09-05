module Staypuft
  class Deployment::VIPS < Deployment::AbstractParamScope

    VIP_NAMES = {
      :ceilometer_admin_vip   => Staypuft::SubnetType::ADMIN_API,
      :ceilometer_private_vip => Staypuft::SubnetType::MANAGEMENT,
      :ceilometer_public_vip  => Staypuft::SubnetType::PUBLIC_API,
      :cinder_admin_vip       => Staypuft::SubnetType::ADMIN_API,
      :cinder_private_vip     => Staypuft::SubnetType::MANAGEMENT,
      :cinder_public_vip      => Staypuft::SubnetType::PUBLIC_API,
      :db_vip                 => Staypuft::SubnetType::MANAGEMENT,
      :glance_admin_vip       => Staypuft::SubnetType::ADMIN_API,
      :glance_private_vip     => Staypuft::SubnetType::MANAGEMENT,
      :glance_public_vip      => Staypuft::SubnetType::PUBLIC_API,
      :heat_admin_vip         => Staypuft::SubnetType::ADMIN_API,
      :heat_private_vip       => Staypuft::SubnetType::MANAGEMENT,
      :heat_public_vip        => Staypuft::SubnetType::PUBLIC_API,
      :heat_cfn_admin_vip     => Staypuft::SubnetType::ADMIN_API,
      :heat_cfn_private_vip   => Staypuft::SubnetType::MANAGEMENT,
      :heat_cfn_public_vip    => Staypuft::SubnetType::PUBLIC_API,
      :horizon_admin_vip      => Staypuft::SubnetType::ADMIN_API,
      :horizon_private_vip    => Staypuft::SubnetType::MANAGEMENT,
      :horizon_public_vip     => Staypuft::SubnetType::PUBLIC_API,
      :keystone_admin_vip     => Staypuft::SubnetType::ADMIN_API,
      :keystone_private_vip   => Staypuft::SubnetType::MANAGEMENT,
      :keystone_public_vip    => Staypuft::SubnetType::PUBLIC_API,
      :loadbalancer_vip       => Staypuft::SubnetType::PUBLIC_API,
      :neutron_admin_vip      => Staypuft::SubnetType::ADMIN_API,
      :neutron_private_vip    => Staypuft::SubnetType::MANAGEMENT,
      :neutron_public_vip     => Staypuft::SubnetType::PUBLIC_API,
      :nova_admin_vip         => Staypuft::SubnetType::ADMIN_API,
      :nova_private_vip       => Staypuft::SubnetType::MANAGEMENT,
      :nova_public_vip        => Staypuft::SubnetType::PUBLIC_API,
      :amqp_vip               => Staypuft::SubnetType::MANAGEMENT,
      :swift_public_vip       => Staypuft::SubnetType::PUBLIC_API,
      :keystone_private_vip   => Staypuft::SubnetType::MANAGEMENT
    }
    # [:ceilometer, :cinder, :db, :glance, :heat, :heat_cfn, :horizon, :keystone, :loadbalancer,
#                 :nova, :neutron, :amqp, :swift]
    COUNT     = VIP_NAMES.size

    def self.param_scope
      'vips'
    end

    param_attr :user_range

    HUMAN = N_('Virtual IP addresses range')

    class Jail < Safemode::Jail
      allow :get
    end

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
      # FIXME: lookup different VIP based on subnet type)
      range[VIP_NAMES.keys.index(name) || raise(ArgumentError, "unknown #{name}")]
    end
  end
end
