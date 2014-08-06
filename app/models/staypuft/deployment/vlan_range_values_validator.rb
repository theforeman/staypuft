module Staypuft
  module Deployment::VlanRangeValuesValidator
    GENERAL_MSG = N_("Start and end vlan IDs required, in format '10:15'")
    INT_VAL_MSG = N_("is not a valid integer between 1 and 4094")
    FIRST_VALID = 1
    LAST_VALID = 4024

    def validate_each(record, attribute, value)

      return if value.empty?

      if value !~ /\A\d+:\d+\Z/
        record.errors.add attribute, GENERAL_MSG
        return
      end

      range_values = value.split(':').map(&:to_i)

      range_values.all? do |value|
        if value.between?(FIRST_VALID, LAST_VALID)
          true
        else
          record.errors.add attribute, "Range boundary #{value} #{INT_VAL_MSG}"
          false
        end
      end or return

      unless range_values[1] >= range_values[0]
        record.errors.add attribute, _("End VLAN ID must be equal to or greater than start VLAN ID.")
      end
    end
  end
end
