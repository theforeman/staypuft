module Staypuft::Concerns::HostgroupExtensions
  extend ActiveSupport::Concern

  included do
    has_one :deployment_role_hostgroup, :dependent => :destroy, :class_name => 'Staypuft::DeploymentRoleHostgroup'
    has_one :parent_deployment, :through => :deployment_role_hostgroup, :class_name => 'Staypuft::Deployment'
    has_one :role, :through => :deployment_role_hostgroup, :class_name => 'Staypuft::Role'

    has_one :deployment, :class_name => 'Staypuft::Deployment', through: :deployment_role_hostgroup

    scope :deploy_order,
          lambda { reorder "#{::Staypuft::DeploymentRoleHostgroup.table_name}.deploy_order" }
  end

  def add_puppetclasses_from_resource(resource)
    if resource.respond_to?(:puppetclasses)
      resource.puppetclasses.each do |puppetclass|
        unless puppetclasses.include?(puppetclass)
          puppetclasses << puppetclass
        end
      end
    end
  end

  def current_param_value(key)
    lookup_value = LookupValue.where(:lookup_key_id => key.id, :id => lookup_values).first
    if lookup_value
      [lookup_value.value, to_label]
    else
      inherited_lookup_value(key)
    end
  end

  def current_param_value_str(key)
    lookup_value, _ = current_param_value(key)
    return key.value_before_type_cast(lookup_value)
  end

  def set_param_value_if_changed(puppetclass, key, value)
    lookup_key         = puppetclass.class_params.where(:key => key).first
    lookup_value_value = current_param_value(lookup_key)[0]
    current_value      = lookup_key.value_before_type_cast(lookup_value_value).to_s.chomp
    if current_value != value
      lookup       = LookupValue.where(:match         => hostgroup.send(:lookup_value_match),
                                       :lookup_key_id => lookup_key.id).first_or_initialize
      lookup.value = value
      lookup.save!
    end
  end

  def own_and_free_hosts
    # TODO update to Discovered only?
    Host::Base.where('hostgroup_id = ? OR hostgroup_id IS NULL', id)
  end

  module ClassMethods
    def get_base_hostgroup
      Hostgroup.where(:name => Setting[:base_hostgroup]).first or raise 'missing base_hostgroup'
    end
  end

  Gem::Version.new(SETTINGS[:version].notag) < Gem::Version.new('1.5') and
      Rails.logger.warn 'Foreman 1.5 is required for nesting of Hostgroups to work properly,' +
                            "please upgrade or expect failures.\n#{__FILE__}:#{__LINE__}"
end
