require 'ipaddress'

module Staypuft
  class SimpleSubnet
    extend ActiveModel::Naming
    include ActiveModel::AttributeMethods

    DHCP_SERVER_TYPE = {
      'external' => 'External DHCP',
      'none' => 'No existing DHCP'
    }
    ATTRS = [:name, :dhcp_server, :network_address, :vlan, :gateway,
             :ip_range_from, :ip_range_to]
    attr_accessor *ATTRS
    attr_accessor :subnet, :deployment
    delegate :errors, :to => :subnet, :allow_nil => true
    delegate :to_key, :to => :subnet, :allow_nil => true

    def initialize(attrs={})
      if attrs.is_a?(::Subnet)
        @subnet = Subnet.find_by_name(attrs.name)
        convert_attributes_from
      else
        @subnet = Subnet.new
        ATTRS.each do |attr|
          self.send("#{attr}=", attrs.has_key?(attr) ? attrs[attr] : nil)
        end
      end
    end

    def save
      @subnet = Subnet.find_or_initialize_by_name(name)
      convert_attributes_to
      @subnet.save
    end

    private

    def convert_attributes_to
      @subnet.boot_mode = self.dhcp_server == 'external' ? ::Subnet::BOOT_MODES[:dhcp] : ::Subnet::BOOT_MODES[:static]
      @subnet.ipam = self.dhcp_server == 'external' ? ::Subnet::IPAM_MODES[:none] : ::Subnet::IPAM_MODES[:db]
      @subnet.gateway = self.gateway
      @subnet.from = self.ip_range_from
      @subnet.to = self.ip_range_to
      @subnet.network = get_network
      @subnet.mask = get_mask
      @subnet.vlanid = self.vlan
    end

    def convert_attributes_from
      self.name = @subnet.name
      if @subnet.boot_mode == ::Subnet::BOOT_MODES[:dhcp] && @subnet.ipam == ::Subnet::IPAM_MODES[:none]
        self.dhcp_server = 'external'
      elsif @subnet.boot_mode == ::Subnet::BOOT_MODES[:static] && @subnet.ipam == ::Subnet::IPAM_MODES[:db]
        self.dhcp_server = 'none'
      else
        raise 'unknown simple subnet combination'
      end

      self.network_address = @subnet.network_address
      self.gateway = @subnet.gateway
      self.vlan = @subnet.vlanid
      self.ip_range_from = @subnet.from
      self.ip_range_to = @subnet.to
    end

    def get_network
      IPAddress::IPv4.new(self.network_address).network.address
    rescue Exception => ex
      self.network_address
    end

    def get_mask
      IPAddress::IPv4.new(self.network_address).netmask if !self.network_address.empty?
    rescue Exception => ex
      self.network_address
    end
  end
end
