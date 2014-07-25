module Staypuft
  class InterfaceAssigner
    attr_accessor :deployment, :interface, :subnet, :errors

    def initialize(deployment, interface, subnet)
      @deployment = deployment
      if interface.is_a?(Nic::Base)
        @interface = interface
      else
        # interface may be Host::Managed which means primary interface, so we create pseudo-interface object
        @interface = Nic::Interface.new(
            :mac => interface.mac,
            :virtual => false,
            :identifier => interface.primary_interface,
            :host => interface,
            :subnet => interface.subnet)
      end

      @subnet = subnet
      @errors = []
    end

    def assign
      if virtual_assignment?
        if (existing = conflicting_interface)
          @errors.push _("Another interface %s on same physical interface with same VLAN exists") % existing.identifier
          return false
        end
        ActiveRecord::Base.transaction do
          unassign_from_other_nics
          assign_virtual
          raise ActiveRecord::Rollback if @errors.present?
          return true
        end
      else
        if @interface.subnet.present? && @interface.subnet != @subnet
          @errors.push _("Interface is already assigned to subnet %s") % @interface.subnet.name
          return false
        end
        ActiveRecord::Base.transaction do
          unassign_from_other_nics
          assign_physical
          raise ActiveRecord::Rollback if @errors.present?
          return true
        end
      end

      return false # we can get there only after rollback
    end

    def unassign
      base = @interface.host.interfaces
      base = virtual_assignment? ? base.virtual : base.physical
      ActiveRecord::Base.transaction do
        base.where(:subnet_id => @subnet.id).each do |interface|
          virtual_assignment? ? unassign_virtual(interface) : unassign_physical(interface)
        end
        raise ActiveRecord::Rollback if @errors.present?
      end
    end

    def virtual_assignment?
      @subnet.vlanid.present?
    end

    private

    def assign_virtual
      interface = Nic::Interface.new(
          :subnet => @subnet,
          :physical_device => @interface.identifier,
          :mac => @interface.mac,
          :host => @interface.host,
          :virtual => true,
          :identifier => @interface.identifier + ".#{@subnet.vlanid}")
      unless interface.save
        @errors.push(*interface.errors.full_messages)
      end
    end

    def assign_physical
      @interface.subnet = @subnet
      unless @interface.save
        @errors.push(*@interface.errors.full_messages)
      end
    end

    # we have to be sure that we remove both physical and virtual,
    # subnet could become virtual/physical meanwhile
    def unassign_from_other_nics
      unassign_physicals
      unassign_virtuals
    end

    def unassign_physicals
      @interface.host.interfaces.physical.where(:subnet_id => @subnet.id).each do |interface|
        unassign_physical(interface)
      end
    end

    def unassign_physical(interface)
      unless interface.update_attribute(:subnet_id, nil)
        @errors.push(interface.errors.full_messages)
      end
    end

    def unassign_virtuals
      @interface.host.interfaces.virtual.where(:subnet_id => @subnet.id).each do |interface|
        unassign_virtual(interface)
      end
    end

    def unassign_virtual(interface)
      unless interface.destroy
        @errors.push _("Interface %s could not be destroyed") % interface.name
      end
    end

    def conflicting_interface
      Nic::Interface.
          where(:identifier => @interface.identifier + ".#{subnet.vlanid}").
          where(['id <> ?', @interface.id]).
          first
    end
  end
end
