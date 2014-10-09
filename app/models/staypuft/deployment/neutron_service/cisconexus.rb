#encoding: utf-8
module Staypuft
  class Deployment::NeutronService::Cisconexus
    include ActiveModel::Serializers::JSON
    include ActiveModel::Validations
    extend ActiveModel::Naming

    attr_accessor :id, :hostname, :ip, :login, :password, :port_map, :ssh_port
    attr_reader :errors

    module Hostname
      HUMAN       = N_('Switch Hostname:')
    end
    module Ip
      HUMAN       = N_('Switch IP Address:')
    end
    module Login
      HUMAN       = N_('Switch Login:')
    end
    module Password
      HUMAN       = N_('Switch Password:')
    end
    module PortMap
      HUMAN       = N_('Port Mappings:')
      HELP_INLINE = N_("hostname: port (One per line)")
    end
    module SshPort
      HUMAN       = N_('SSH Port:')
    end

    class IpValueValidator < ActiveModel::EachValidator
      include Staypuft::Deployment::IpAddressValidator
    end

    class PortMapValueValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return if value.empty?

        if value.each_line.collect { |line| line.split(':').count == 2 }.all?
          true
        else
          record.errors.add attribute, "One per line, 'hostname: port'"
          false
        end
      end
    end

    validates :hostname,
              presence: true
    validates :ip,
              presence: true,
              ip_value: true
    validates :login,
              presence: true,
              format: /\A[a-zA-Z\d][\w\.\-]*[\w\-]\z/,
              length: { maximum: 16 }
    validates :password,
              presence: true,
              format: /\A[!-~]+\z/,
              length: { minimum:3, maximum: 16 }
    validates :port_map,
              presence: true,
              port_map_value: true
    validates :ssh_port,
              presence: true,
              numericality: { only_integer: true,
                              greater_than_or_equal_to: 1,
                              less_than_or_equal_to: 65535 }

    def initialize(attrs = {})
      @errors = ActiveModel::Errors.new(self)
      # Default ssh port to 22, but let args override
      self.ssh_port = 22
      self.attributes = attrs
    end

    def self.human_attribute_name(attr, options = {})
      attr
    end

    def self.lookup_ancestors
      [self]
    end

    def config_hash
      { "ip_address" => ip, "username" => login, "password" => password,
        "ssh_port" => ssh_port, "servers" => port_map_hash }
    end

    def port_map_hash
      Hash[port_map.each_line.map do |line|
        server = line.split(':')
        [ server.first.strip, server.last.strip ]
      end]
    end

    def attributes
      { 'hostname' => nil, 'ip' => nil, 'login' => nil, 'password' => nil,
        'port_map' => nil, 'ssh_port' => nil }
    end

    def attributes=(attrs)
      attrs.each { |attr, value| send "#{attr}=", value } unless attrs.nil?
    end

  end
end
