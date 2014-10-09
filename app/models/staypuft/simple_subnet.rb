require 'ipaddress'

module Staypuft
  class SimpleSubnet
    extend ActiveModel::Naming
    include ActiveModel::AttributeMethods
    include ActiveModel::Validations

    DHCP_SERVER_TYPE = {
      'external' => 'External DHCP',
      'none' => 'No existing DHCP'
    }
    ATTRS = [:name, :dhcp_server, :network_address, :vlan, :gateway,
             :ip_range_from, :ip_range_to]
    attr_accessor *ATTRS
    attr_accessor :subnet, :deployment
    delegate :to_key, :to => :subnet, :allow_nil => true

    validates :name, :dhcp_server, :network_address, presence: true
    validates :gateway, :presence => true,
                        :if => Proc.new { |subnet| subnet.dhcp_server == 'none' }
    validates_format_of :network_address, :with => Net::Validations::IP_REGEXP
    validates_format_of :gateway, :with => Net::Validations::IP_REGEXP,
                                  :if => Proc.new { |subnet| subnet.dhcp_server == 'none' }
    validate :validate_ranges, :if => Proc.new { |subnet| subnet.dhcp_server == 'none' }

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
      if self.valid?
        @subnet = Subnet.find_or_initialize_by_name(name)
        convert_attributes_to
        @subnet.save
      else
        false
      end
    end

    private

    def convert_attributes_to
      @subnet.boot_mode = self.dhcp_server == 'external' ? ::Subnet::BOOT_MODES[:dhcp] : ::Subnet::BOOT_MODES[:static]
      @subnet.ipam = self.dhcp_server == 'external' ? ::Subnet::IPAM_MODES[:none] : ::Subnet::IPAM_MODES[:db]
      @subnet.network = get_network
      @subnet.mask = get_mask
      @subnet.vlanid = self.vlan
      if self.dhcp_server == 'none'
        @subnet.gateway = self.gateway
        @subnet.from = self.ip_range_from
        @subnet.to = self.ip_range_to
      end
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
      errors.add(:network_address, _("invalid Network Address"))
      self.network_address
    end

    def get_mask
      IPAddress::IPv4.new(self.network_address).netmask
    rescue Exception => ex
      errors.add(:network_address, _("invalid Network Address Mask"))
      self.network_address
    end

    def validate_ranges
      errors.add(:ip_range_from, _("invalid IP address")) if ip_range_from.present? && !(ip_range_from =~ Net::Validations::IP_REGEXP)
      errors.add(:ip_range_to, _("invalid IP address")) if ip_range_to.present? && !(ip_range_to =~ Net::Validations::IP_REGEXP)
      if ip_range_from.present? or ip_range_to.present?
        errors.add(:ip_range_from, _("must be specified if 'IP Range End' is defined"))   if ip_range_from.blank?
        errors.add(:ip_range_to,   _("must be specified if 'IP Range Start' is defined")) if ip_range_to.blank?
      end
    end

  end
end
