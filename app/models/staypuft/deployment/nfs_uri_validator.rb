module Staypuft
  module Deployment::NfsUriValidator
    include Staypuft::Deployment::IpCheck

    INVALID_URI_MESSAGE = N_('Specify NFS URI as &lt;server&gt;:&lt;local path&gt;')
    def validate_each(record, attribute, value)
      return if value.empty?
      match = /(.+):(.+)/.match(value)
      if match
        check_ip_or_hostname(record, attribute, match[1])
      else
        record.errors.add attribute, INVALID_URI_MESSAGE
        false
      end
    end
  end
end
