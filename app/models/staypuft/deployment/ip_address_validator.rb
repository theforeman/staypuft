module Staypuft
  module Deployment::IpAddressValidator
    include Staypuft::Deployment::IpCheck

    def validate_each(record, attribute, value)
      return if value.empty?
      check_ip_or_hostname(record, attribute, value)
    end
  end
end
