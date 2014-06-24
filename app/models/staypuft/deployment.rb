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
                    :amqp_provider, :layout_name, :networking, :hypervisor
    after_save :update_hostgroup_name
    before_validation :set_default_ui_param_values, :on => :create
    after_validation :check_form_complete
    before_destroy :prepare_destroy

    belongs_to :layout
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

    def self.param_attr(*names)
      names.each do |name|
        ivar_name  = :"@#{name}"
        param_name = "ui::deployment::#{name}"

        define_method name do
          instance_variable_get(ivar_name) or
              instance_variable_set(ivar_name,
                                    hostgroup.group_parameters.find_by_name(param_name).try(:value))
        end

        define_method "#{name}=" do |value|
          instance_variable_set(ivar_name, value)
        end

        after_save do
          hostgroup.
              group_parameters.
              find_or_create_by_name(param_name).
              update_attributes!(value: instance_variable_get(ivar_name))
        end
      end
    end

    # TODO hide this in UI
    param_attr :amqp_provider, :networking, :layout_name, :hypervisor

    module AmqpProvider
      RABBITMQ = 'rabbitmq'
      QPID     = 'qpid'
      LABELS   = { RABBITMQ => N_('RabbitMQ'), QPID => N_('Qpid') }
      TYPES    = LABELS.keys
      HUMAN    = N_('Messaging provider')
    end

    validates :amqp_provider, :presence => true, :inclusion => { :in => AmqpProvider::TYPES }

    module Networking
      NOVA    = 'nova'
      NEUTRON = 'neutron'
      LABELS  = { NOVA => N_('Nova Network'), NEUTRON => N_('Neutron Networking') }
      TYPES   = LABELS.keys
      HUMAN   = N_('Networking')
    end

    validates :networking, :presence => true, :inclusion => { :in => Networking::TYPES }

    module LayoutName
      NON_HA   = 'Controller / Compute'
      HA       = 'High Availability Controllers / Compute'
      LABELS   = { NON_HA => N_('Controller / Compute'),
                   HA     => N_('High Availability Controllers / Compute') }
      TYPES    = LABELS.keys
      HUMAN    = N_('High Availability')
    end

    validates :layout_name, presence: true, inclusion: { in: LayoutName::TYPES }

    module Hypervisor
      KVM  = 'kvm'
      QEMU = 'qemu'
      LABELS   = { KVM => N_('Libvirt/KVM'),
                   QEMU  => N_('Libvirt/QEMU') }
      TYPES    = LABELS.keys
      HUMAN    = N_('Hypervisor')
    end

    validates :hypervisor, presence: true, inclusion: { in: Hypervisor::TYPES }


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
      new_layout = Layout.where(:name =>layout_name, :networking => networking).first
      layout = new_layout
      old_role_hostgroups_arr = deployment_role_hostgroups.to_a
      layout.layout_roles.each do |layout_role|
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
    def update_hostgroup_name
      hostgroup.name = self.name
      hostgroup.save!
    end

    # This needs to set all UI params. For service-level UI params
    # this can call similar helper methods on the service helper classes to delegate
    def set_default_ui_param_values
      self.layout    = Layout.where(:name       => LayoutName::NON_HA,
                               :networking => Networking::NOVA).first
      deployment_hostgroup = ::Hostgroup.new name: name, parent: Hostgroup.get_base_hostgroup
      deployment_hostgroup.save!

      self.hostgroup = deployment_hostgroup

      self.amqp_provider = AmqpProvider::RABBITMQ
      self.layout_name   = LayoutName::NON_HA
      self.networking    = Networking::NOVA
      self.hypervisor    = Hypervisor::KVM
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
  end
end
