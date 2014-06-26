module Staypuft
  class Deployment::NovaService < Deployment::AbstractParamScope
    def self.param_scope
      'nova'
    end

    param_attr :nova_network

    module NovaNetwork
      FLAT      = 'flat'
      FLAT_DHCP = 'flatdhcp'
      LABELS    = { FLAT      => N_('Flat'),
                    FLAT_DHCP => N_('FlatDHCP') }
      TYPES     = LABELS.keys
    end

    validates :nova_network, presence: true, inclusion: { in: NovaNetwork::TYPES }
  end
end
