module Staypuft
  class Deployment < ActiveRecord::Base

    # Form step states
    STEP_SETTINGS =      :settings
    STEP_CONFIGURATION = :configuration
    STEP_COMPLETE =      :complete
    STEP_SELECTION =     :selection
    
    NEW_NAME_PREFIX="uninitialized_"

    attr_accessible :description, :name, :layout_id, :layout
    after_save :update_hostgroup_name
    after_validation :check_form_complete

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

    def destroy
      child_hostgroups.each do |h|
        h.destroy
      end
      #do the main destroy
      super
    end

    # After setting or changing layout, update the set of child hostgroups,
    # adding groups for any roles not already represented, and removing others
    # no longer needed.
    def update_hostgroup_list
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

    # If layout networking is set to 'neutron', then set include_neutron and
    # neutron on the hostgroup if it includes the "quickstack::pacemaker::params"
    #  puppetclass
    def set_networking_params
      child_hostgroups.each do |the_hostgroup|
        the_hostgroup.puppetclasses.each do |pclass|
          if pclass.class_params.where(:key => "include_neutron").first
            the_hostgroup.set_param_value_if_changed(pclass, "include_neutron",
                                                     layout.networking == 'neutron')
          end
          if pclass.class_params.where(:key => "neutron").first
            the_hostgroup.set_param_value_if_changed(pclass, "neutron",
                                                     layout.networking == 'neutron')
          end
        end
      end
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

    # Checks to see if the form step was the last in the series.  If so it sets
    # the form_step field to complete.
    def check_form_complete
      self.form_step = Deployment::STEP_COMPLETE if self.form_step.to_sym == Deployment::STEP_CONFIGURATION
    end
  end
end
