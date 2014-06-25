module Staypuft
  class Deployment < ActiveRecord::Base

    # Form step states
    STEP_INACTIVE      = :inactive
    STEP_SETTINGS      = :settings
    STEP_CONFIGURATION = :configuration
    STEP_COMPLETE      = :complete
    STEP_OVERVIEW      = :overview

    NEW_NAME_PREFIX ="uninitialized_"

    attr_accessible :description, :name, :layout_id, :layout,
                    :amqp_provider, :layout_name, :networking, :hypervisor, :platform
    after_save :update_hostgroup_name
    after_validation :check_form_complete
    before_destroy :prepare_destroy

    belongs_to :layout

    # needs to be defined before hostgroup association
    before_destroy { child_hostgroups.each &:destroy }
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

    def initialize(attributes = {}, options = {})
      super({ amqp_provider: AmqpProvider::RABBITMQ,
              layout_name:   LayoutName::NON_HA,
              hypervisor:    Hypervisor::KVM,
              networking:    Networking::NOVA,
              platform:      Platform::RHEL6 }.merge(attributes),
            options)


      self.nova.nova_network = NovaService::NovaNetwork::FLAT
      self.passwords.set_defaults

      self.hostgroup = Hostgroup.new(name: name, parent: Hostgroup.get_base_hostgroup)
      self.layout    = Layout.where(:name       => self.layout_name,
                                    :networking => self.networking).first
    end

    def self.param_scope
      'deployment'
    end

    module AttributeParamStorage
      # FIXME: this is probably the wrong way to do this, but it's a placeholder
      # since the views and form helpers seem to want []-based access


      def param_attr(*names)
        names.each do |name|
          ivar_name  = :"@#{name}"
          param_name = "ui::#{param_scope}::#{name}"

          define_method name do
            instance_variable_get(ivar_name) or
                instance_variable_set(ivar_name,
                                      hostgroup.group_parameters.find_by_name(param_name).try(:value))
          end

          define_method "#{name}=" do |value|
            raise ArgumentError if value.nil?
            instance_variable_set(ivar_name, value)
          end

          after_save do
            value = send(name)
            if value.blank?
              hostgroup.
                  group_parameters.
                  find_by_name(param_name).try(:destroy)
            else
              param = hostgroup.
                  group_parameters.
                  find_or_initialize_by_name(param_name)
              param.update_attributes!(value: value)
            end
          end
        end
      end
    end

    extend AttributeParamStorage

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
      LABELS  = { NOVA => N_('Nova Network'), NEUTRON => N_('Neutron Networking') }
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

    module Hypervisor
      KVM    = 'kvm'
      QEMU   = 'qemu'
      LABELS = { KVM  => N_('Libvirt/KVM'),
                 QEMU => N_('Libvirt/QEMU') }
      TYPES  = LABELS.keys
      HUMAN  = N_('Hypervisor')
    end

    module Platform
      RHEL7  = 'rhel7'
      RHEL6  = 'rhel6'
      LABELS = { RHEL7 => N_('Red Hat Enterprise Linux Opestack Platfom 5 with RHEL 7'),
                 RHEL6 => N_('Red Hat Enterprise Linux Opestack Platfom 5 with RHEL 6') }
      TYPES  = LABELS.keys
      HUMAN  = N_('Platform')
    end

    param_attr :amqp_provider, :networking, :layout_name, :hypervisor, :platform
    validates :hypervisor, presence: true, inclusion: { in: Hypervisor::TYPES }
    validates :amqp_provider, :presence => true, :inclusion => { :in => AmqpProvider::TYPES }
    validates :networking, :presence => true, :inclusion => { :in => Networking::TYPES }
    validates :layout_name, presence: true, inclusion: { in: LayoutName::TYPES }
    validates :platform, presence: true, inclusion: { in: Platform::TYPES }

    # TODO(mtaylor)
    # Use conditional validations to validate the deployment multi-step form.
    # deployment.form_step should be used to check the form step the user is
    # currently on.
    # e.g.
    # validates :name, :presence => true, :if => :form_step_is_configuation?

    scoped_search :on => :name, :complete_value => :true

    def self.available_locks
      [:deploy]
    end

    # After setting or changing layout, update the set of child hostgroups,
    # adding groups for any roles not already represented, and removing others
    # no longer needed.
    def update_hostgroup_list
      new_layout              = Layout.where(:name => layout_name, :networking => networking).first
      old_role_hostgroups_arr = deployment_role_hostgroups.to_a
      new_layout.layout_roles.each do |layout_role|
        role_hostgroup = deployment_role_hostgroups.where(:role_id => layout_role.role).first_or_initialize do |drh|
          drh.hostgroup = Hostgroup.new(name: layout_role.role.name, parent: hostgroup)
        end

        role_hostgroup.hostgroup.add_puppetclasses_from_resource(layout_role.role)
        layout_role.role.services.each do |service|
          role_hostgroup.hostgroup.add_puppetclasses_from_resource(service)
        end
        role_hostgroup.hostgroup.save!

        role_hostgroup.deploy_order = layout_role.deploy_order
        role_hostgroup.save!

        old_role_hostgroups_arr.delete(role_hostgroup)
      end
      # delete any prior mappings that remain
      old_role_hostgroups_arr.each do |role_hostgroup|
        role_hostgroup.hostgroup.destroy
      end
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

    def form_complete?
      self.form_step.to_sym == Deployment::STEP_COMPLETE
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
      hosts.each { |host| host.open_stack_unassign }
      child_hostgroups.each { |hg| hg.destroy }
    end
    public

    # TODO move to its own file
    class AbstractService
      include ActiveModel::Validations
      extend ActiveModel::Callbacks
      extend AttributeParamStorage
      define_model_callbacks :save, :only => [:after]

      def self.param_scope
        raise NotImplementedError
      end

      attr_reader :deployment

      def initialize(deployment)
        @deployment = deployment
      end

      def hostgroup
        deployment.hostgroup
      end

      def marked_for_destruction?
        false
      end
    end

    class NovaService < AbstractService
      def self.param_scope
        'nova'
      end

      param_attr :nova_network

      module NovaNetwork
        FLAT      = 'flat'
        FLAT_DHCP = 'flatdhcp'
        LABELS    = { FLAT      => N_('Flat'),
                      FLAT_DHCP => N_('FlatDHCP') }
        TYPES     = LABELS.keys
      end

      validates :nova_network, presence: true, inclusion: { in: NovaNetwork::TYPES }
    end

    # validates_associated :nova

    def nova
      @nova_service ||= NovaService.new self
    end

    class PasswordService < AbstractService
      PASSWORD_LIST = :admin, :ceilometer_user, :cinder_db, :cinder_user,
          :glance_db, :glance_user, :heat_db, :heat_user, :heat_cfn_user, :mysql_root,
          :keystone_db, :keystone_user, :neutron_db, :neutron_user, :nova_db, :nova_user,
          :swift_admin, :swift_user, :amqp, :amqp_nssdb, :keystone_admin_token,
          :ceilometer_metering_secret, :heat_auth_encrypt_key, :horizon_secret_key,
          :swift_shared_secret, :neutron_metadata_proxy_secret

      OTHER_ATTRS_LIST = :mode, :single_password

      def self.param_scope
        'passwords'
      end

      param_attr *OTHER_ATTRS_LIST, *PASSWORD_LIST

      def attributes=(attr_list)
        attr_list.each { |attr, value| send "#{attr}=", value }
      end

      module Mode
        SINGLE = 'single'
        RANDOM = 'random'
        LABELS = { RANDOM => N_('Generate random password for each service'),
                   SINGLE => N_('Use single password for all services') }
        TYPES  = LABELS.keys
        HUMAN  = N_('Service Password')
      end

      validates :mode, presence: true, inclusion: { in: Mode::TYPES }

      # using old hash syntax here since if:, while validly parsing as :if => in
      # ruby itself, in irb the parser treats it as an if keyword, as does both
      # emacs and rubymine, which really messes with indention, etc.
      validates :single_password,
                :presence     => true,
                :confirmation => true,
                :if           => :single_mode?,
                :length       => { minimum: 6 }
      validates :single_password_confirmation,
                :presence => true,
                :if       => :single_mode?

      def set_defaults
        self.mode = Mode::RANDOM
        PASSWORD_LIST.each do |password_field|
          self.send("#{password_field}=", SecureRandom.hex)
        end
      end

      def single_mode?
        mode == Mode::SINGLE
      end

      def effective_value(password_field)
        if single_mode?
          single_password
        else
          send(password_field)
        end
      end

      def id # compatibility with password_f
        single_password
      end
    end

    validates_associated :passwords

    def passwords
      @password_service ||= PasswordService.new self
    end

    after_save do
      nova.run_callbacks :save
      passwords.run_callbacks :save
      true
    end

  end
end
