module Staypuft
  class Deployment::CinderService < Deployment::AbstractParamScope
    def self.param_scope
      'cinder'
    end

    param_attr :driver_backend, :nfs_uri, :rbd_secret_uuid
    after_save :set_lvm_ptable

    module DriverBackend
      LVM        = 'lvm'
      NFS        = 'nfs'
      CEPH       = 'ceph'
      EQUALLOGIC = 'equallogic'
      LABELS     = { LVM        => N_('LVM'),
                     NFS        => N_('NFS'),
                     CEPH       => N_('Ceph'),
                     EQUALLOGIC => N_('EqualLogic') }
      TYPES      = LABELS.keys
      HUMAN      = N_('Choose Driver Backend')
    end
    validates :driver_backend, presence: true, inclusion: { in: lambda { |c| c.backend_types_for_layout } }

    module NfsUri
      HUMAN       = N_('NFS URI:')
      HUMAN_AFTER = Deployment::GlanceService::NFS_HELP
    end
    validates :nfs_uri,
              :presence => true,
              :if       => :nfs_backend?
    # TODO: uri validation

    # TODO: add EqualLogic UI parameters


    class Jail < Safemode::Jail
      allow :lvm_backend?, :nfs_backend?, :nfs_uri, :ceph_backend?, :equallogic_backend?,
        :rbd_secret_uuid
    end

    def set_defaults
      self.driver_backend = DriverBackend::LVM
      self.rbd_secret_uuid = SecureRandom.uuid
    end

    # cinder config always shows up
    def active?
      true
    end

    def lvm_backend?
      !self.deployment.ha? && (self.driver_backend == DriverBackend::LVM)
    end

    def nfs_backend?
      self.driver_backend == DriverBackend::NFS
    end

    def ceph_backend?
      self.driver_backend == DriverBackend::CEPH
    end

    def equallogic_backend?
      self.driver_backend == DriverBackend::EQUALLOGIC
    end


    # view should use this rather than DriverBackend::LABELS to hide LVM for HA.
    # TODO: Add back EQUALLOGIC as it's suppoirted
    def backend_labels_for_layout
      ret_list = DriverBackend::LABELS.clone
      ret_list.delete(DriverBackend::LVM) if self.deployment.ha?
      # TODO: remove this line when EqualLogic is supported
      ret_list.delete(DriverBackend::EQUALLOGIC)

      ret_list
    end
    def backend_types_for_layout
      ret_list = DriverBackend::TYPES.clone
      ret_list.delete(DriverBackend::LVM) if self.deployment.ha?
      # TODO: remove this line when EqualLogic is supported
      ret_list.delete(DriverBackend::EQUALLOGIC)

      ret_list
    end

    def param_hash
      { "driver_backend" => driver_backend, "nfs_uri" => nfs_uri,
        "rbd_secret_uuid" => rbd_secret_uuid }
    end

    def lvm_ptable
      Ptable.find_by_name('LVM with cinder-volumes')
    end

    private

    def set_lvm_ptable
      if (hostgroup = deployment.controller_hostgroup)
        ptable = lvm_ptable
       if (lvm_backend? && ptable.nil?)
          Rails.logger.error "Missing Partition Table 'LVM with cinder-volumes'"
        end
        if (lvm_backend? && ptable)
          hostgroup.ptable = ptable
        else
          hostgroup.ptable = nil
        end
        hostgroup.save!
      end
    end
  end
end
