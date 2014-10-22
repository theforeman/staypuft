module Staypuft
  class InterfaceAssigner
    attr_accessor :deployment, :interface, :subnet, :errors

    def initialize(deployment, interface, subnet)
      @deployment = deployment
      if interface.is_a?(Nic::Base)
        @interface = interface
      else
        # interface may be Host::Managed which means primary interface, so we create pseudo-interface object
        @interface = Nic::Managed.new(
                :mac => interface.mac,
                :virtual => false,
                :identifier => interface.primary_interface,
                :host => interface,
                :subnet => interface.subnet)
      end

      @host = @interface.host
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
      base = @host.interfaces

      # we should make sure that we delete from right base, subnet vlan may have changed meanwhile which affects
      # virtual_assignment? result
      if @interface.is_a?(Nic::Bond)
        base = base.virtual # we want to find bond and vlans (both virtual)
      else
        base = virtual_assignment? ? base.virtual : base.physical
      end

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

    def build_new_interface(klass = Nic::Managed)
      klass.new(
              :attached_to => @interface.identifier,
              :mac => @interface.mac,
              :host => @host,
              :virtual => true,
              :identifier => @interface.identifier + ".#{@subnet.vlanid}"
          )
    end

    def assign_virtual
      interface = build_new_interface
      assign_interface(interface)
    end

    def assign_physical
      assign_interface(@interface)
    end

    def assign_interface(interface)
      interface.subnet = @subnet
      suggest_ip(interface) if @subnet.ipam?
      unless interface.save
        @errors.push(*interface.errors.full_messages)
      end
    end

    # we have to be sure that we remove both physical and virtual,
    # subnet could become virtual/physical meanwhile
    def unassign_from_other_nics
      unassign_physicals
      unassign_bonds
      unassign_virtuals
    end

    def unassign_physicals
      @host.interfaces.physical.non_vip.where(:subnet_id => @subnet.id).each do |interface|
        unassign_physical(interface)
      end
    end

    # if subnet has IP suggesting enabled we also clear the IP that was suggested
    # this IP will be used for another interface
    def unassign_physical(interface)
      interface.ip = nil if interface.subnet.ipam?
      interface.subnet_id = nil
      unless interface.save
        @errors.push(interface.errors.full_messages)
      end
    end

    def unassign_bonds
      @host.interfaces.bonds.where(:subnet_id => @subnet.id).each do |interface|
        unassign_physical(interface)
      end
    end

    def unassign_virtuals
      @host.interfaces.virtual.where('type <> ?', Nic::Bond.to_s).where(:subnet_id => @subnet.id).each do |interface|
        unassign_virtual(interface)
      end
    end

    def unassign_virtual(interface)
      unless interface.destroy
        @errors.push _("Interface %s could not be destroyed") % interface.name
      end
    end

    def conflicting_interface
      @host.interfaces.
          where(:identifier => @interface.identifier + ".#{subnet.vlanid}").
          where(['id <> ?', @interface.id]).
          first
    end

    def suggest_ip(interface)
      interface.ip = @subnet.unused_ip if interface.ip.blank?
    end
  end
end
