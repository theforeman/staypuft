module Staypuft
  module Deployment::IpCheck
    NOT_RANGE_MSG = N_("Specify single IP address, not range")
    INVALID_IP_OR_FQDN_MSG = N_("Invalid IP address or FQDN supplied")

    def check_ip_or_hostname(record, attribute, value)
      begin
        ip_addr = IPAddr.new(value)
        ip_range = ip_addr.to_range
        if ip_range.begin == ip_range.end
          true
        else
          record.errors.add attribute, NOT_RANGE_MSG
          false
        end
      rescue
        # not IP addr
        # validating as fqdn
        if /(?=^.{1,254}$)(^(((?!-)[a-zA-Z0-9-]{1,63}(?<!-))|((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63})$)/ =~ value
          true
        else
          record.errors.add attribute, INVALID_IP_OR_FQDN_MSG
          false
        end
      end
    end
  end
end
