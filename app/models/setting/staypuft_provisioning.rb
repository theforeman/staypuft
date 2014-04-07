class Setting::StaypuftProvisioning < ::Setting
  BLANK_ATTRS << "base_hostgroup"

  def self.load_defaults
    # Check the table exists
    return unless super

    # fixme: not sure about the best way to store AR objects in settings.
    # for now, since we know type, store ID. It might be good to add custom
    # get/set code to decode the ID value into a hostgroup (which methods to call?)
    self.transaction do
      [
       self.set("base_hostgroup", _("The base hostgroup which contains the base provisioning config"), 'base_hostgroup')
      ].compact.each { |s| self.create s.update(:category => "Setting::StaypuftProvisioning")}
    end

    true

  end

end
