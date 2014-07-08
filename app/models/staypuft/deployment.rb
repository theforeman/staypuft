module Staypuft
  class Deployment < ActiveRecord::Base

    # Form step states
    STEP_INACTIVE      = :inactive
    STEP_SETTINGS      = :settings
    STEP_CONFIGURATION = :configuration
    STEP_COMPLETE      = :complete
    STEP_OVERVIEW      = :overview

    NEW_NAME_PREFIX = 'uninitialized_'

    attr_accessible :description, :name, :layout_id, :layout,
                    :amqp_provider, :layout_name, :networking, :platform
    after_save :update_hostgroup_name
    after_validation :check_form_complete

    belongs_to :layout

    # needs to be defined before hostgroup association
    before_destroy :prepare_destroy
    belongs_to :hostgroup, :dependent => :destroy

    has_many :deployment_role_hostgroups, :dependent => :destroy
    has_many :child_hostgroups,
             :through    => :deployment_role_hostgroups,
             :class_name => 'Hostgroup',
             :source     => :hostgroup

    has_many :roles,
             :through => :deployment_role_hostgroups
    has_many :roles_ordered,
             :through => :deployment_role_hostgroups,
             :source  => :role,
             :order   => "#{::Staypuft::DeploymentRoleHostgroup.table_name}.deploy_order"

    has_many :services, :through => :roles
    has_many :hosts, :through => :child_hostgroups

    validates :name, :presence => true, :uniqueness => true

    validates :layout, :presence => true
    validates :hostgroup, :presence => true

    after_validation :check_form_complete
    before_save :update_layout
    after_save :update_based_on_settings

    SCOPES = [[:nova, :@nova_service, NovaService],
              [:neutron, :@neutron_service, NeutronService],
              [:glance, :@glance_service, GlanceService],
              [:cinder, :@cinder_service, CinderService],
              [:passwords, :@passwords, Passwords],
              [:vips, :@vips, VIPS],
              [:ips, :@ips, IPS]]

    SCOPES.each do |name, ivar, scope_class|
      define_method name do
        instance_variable_get ivar or
            instance_variable_set ivar, scope_class.new(self)
      end
      after_save { send(name).run_callbacks :save }
    end

    validates_associated :nova, :if => lambda { |d| d.form_step_is_past_configuration? && d.nova.active? }
    validates_associated :neutron, :if => lambda { |d| d.form_step_is_past_configuration? && d.neutron.active? }
    validates_associated :glance, :if =>  lambda {|d| d.form_step_is_past_configuration? && d.glance.active? }
    validates_associated :cinder, :if =>  lambda {|d| d.form_step_is_past_configuration? && d.cinder.active? }
    validates_associated :passwords

    def initialize(attributes = {}, options = {})
      super({ amqp_provider: AmqpProvider::RABBITMQ,
              layout_name:   LayoutName::NON_HA,
              networking:    Networking::NEUTRON,
              platform:      Platform::RHEL7 }.merge(attributes),
            options)

      self.hostgroup = Hostgroup.new(name: name, parent: Hostgroup.get_base_hostgroup)

      self.nova.set_defaults
      self.neutron.set_defaults
      self.glance.set_defaults
      self.cinder.set_defaults
      self.passwords.set_defaults
      self.layout = Layout.where(:name       => self.layout_name,
                                 :networking => self.networking).first
    end

    extend AttributeParamStorage

    # Returns a list of hosts that are currently being deployed.
    def in_progress_hosts(hostgroup)
      return in_progress? ? hostgroup.openstack_hosts : {}
    end

    # Helper method for checking whether this deployment is in progress or not.
    def in_progress?
      ForemanTasks::Lock.locked? self, nil
    end

    # Returns all deployed hosts with no errors (default behaviour).  Set
    # errors=true to return all deployed hosts that have errors
    def deployed_hosts(hostgroup, errors=false)
      in_progress? ? {} : hostgroup.openstack_hosts(errors)
    end

    def self.param_scope
      'deployment'
    end

    module AmqpProvider
      RABBITMQ = 'rabbitmq'
      QPID     = 'qpid'
      LABELS   = { RABBITMQ => N_('RabbitMQ'), QPID => N_('Qpid') }
      TYPES    = LABELS.keys
      HUMAN    = N_('Messaging provider')
    end

    module Networking
      NOVA    = 'nova'
      NEUTRON = 'neutron'
      LABELS  = { NEUTRON => N_('Neutron Networking'), NOVA => N_('Nova Network') }
      TYPES   = LABELS.keys
      HUMAN   = N_('Networking')
    end

    module LayoutName
      NON_HA = 'Controller / Compute'
      HA     = 'High Availability Controllers / Compute'
      LABELS = { NON_HA => N_('Controller / Compute'),
                 HA     => N_('High Availability Controllers / Compute') }
      TYPES  = LABELS.keys
      HUMAN  = N_('High Availability')
    end

    module Platform
      RHEL7  = 'rhel7'
      RHEL6  = 'rhel6'
      LABELS = { RHEL7 => N_('Red Hat Enterprise Linux OpenStack Platform 5 with RHEL 7'),
                 RHEL6 => N_('Red Hat Enterprise Linux OpenStack Platform 5 with RHEL 6') }
      TYPES  = LABELS.keys
      HUMAN  = N_('Platform')
    end

    param_attr :amqp_provider, :networking, :layout_name, :platform
    validates :amqp_provider, :presence => true, :inclusion => { :in => AmqpProvider::TYPES }
    validates :networking, :presence => true, :inclusion => { :in => Networking::TYPES }
    validates :layout_name, presence: true, inclusion: { in: LayoutName::TYPES }
    validates :platform, presence: true, inclusion: { in: Platform::TYPES }

    class Jail < Safemode::Jail
      allow :amqp_provider, :networking, :layout_name, :platform, :nova_networking?, :neutron_networking?,
        :nova, :neutron, :glance, :cinder, :passwords, :vips, :ips, :ha?
    end

    # TODO(mtaylor)
    # Use conditional validations to validate the deployment multi-step form.
    # deployment.form_step should be used to check the form step the user is
    # currently on.
    # e.g.
    # validates :name, :presence => true, :if => :form_step_is_configuration?

    scoped_search :on => :name, :complete_value => :true

    def self.available_locks
      [:deploy]
    end

    def services_hostgroup_map
      deployment_role_hostgroups.map do |deployment_role_hostgroup|
        deployment_role_hostgroup.services.reduce({}) do |h, s|
          h.update s => deployment_role_hostgroup.hostgroup
        end
      end.reduce(&:merge)
    end

    def deployed?
      self.hosts.any?(&:open_stack_deployed?)
    end

    def form_step_is_configuration?
      self.form_step.to_sym == Deployment::STEP_CONFIGURATION
    end

    def form_step_is_past_configuration?
      self.form_step_is_configuration? || self.form_complete?
    end

    def form_complete?
      self.form_step.to_sym == Deployment::STEP_COMPLETE
    end

    def ha?
      self.layout_name == LayoutName::HA
    end

    def nova_networking?
      networking == Networking::NOVA
    end

    def neutron_networking?
      networking == Networking::NEUTRON
    end

    private

    def update_layout
      self.layout = Layout.where(:name => layout_name, :networking => networking).first
    end

    def update_based_on_settings
      update_hostgroup_name
      update_operating_system
      update_hostgroup_list
    end

    def update_hostgroup_name
      hostgroup.name = self.name
      hostgroup.save!
    end

    def update_operating_system
      self.hostgroup.operatingsystem = case platform
                                       when Platform::RHEL6
                                         Operatingsystem.where(name: 'RedHat', major: '6', minor: '5').first
                                       when Platform::RHEL7
                                         Operatingsystem.where(name: 'RedHat', major: '7', minor: '0').first
                                       end or
          raise 'missing Operatingsystem'
      self.hostgroup.save!
    end

    # After setting or changing layout, update the set of child hostgroups,
    # adding groups for any roles not already represented, and removing others
    # no longer needed.
    def update_hostgroup_list
      old_deployment_role_hostgroups = deployment_role_hostgroups.to_a
      new_deployment_role_hostgroups = layout.layout_roles.map do |layout_role|
        deployment_role_hostgroup = deployment_role_hostgroups.where(:role_id => layout_role.role).first_or_initialize do |drh|
          drh.hostgroup = Hostgroup.new(name: layout_role.role.name, parent: hostgroup)
        end

        deployment_role_hostgroup.hostgroup.add_puppetclasses_from_resource(layout_role.role)
        layout_role.role.services.each do |service|
          deployment_role_hostgroup.hostgroup.add_puppetclasses_from_resource(service)
        end
        # deployment_role_hostgroup.hostgroup.save!

        deployment_role_hostgroup.deploy_order = layout_role.deploy_order
        deployment_role_hostgroup.save!

        deployment_role_hostgroup
      end

      # delete any prior mappings that remain
      (old_deployment_role_hostgroups - new_deployment_role_hostgroups).each &:destroy
    end

    # Checks to see if the form step was the last in the series.  If so it sets
    # the form_step field to complete.
    def check_form_complete
      self.form_step = Deployment::STEP_COMPLETE if self.form_step.to_sym == Deployment::STEP_CONFIGURATION
    end

    def prepare_destroy
      hosts.each &:open_stack_unassign
      child_hostgroups.each &:destroy
    end

  end
end
