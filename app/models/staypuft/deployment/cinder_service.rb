module Staypuft
  class Deployment::CinderService < Deployment::AbstractParamScope
    def self.param_scope
      'cinder'
    end

    param_attr :driver_backend, :nfs_uri, :nfs_mount_options

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
    validates :driver_backend, presence: true, inclusion: { in: DriverBackend::TYPES }

    module NfsUri
      HUMAN = N_('NFS URI ("example.com/path/to/mount"):')
    end
    validates :nfs_uri,
              :presence => true,
              :if       => :nfs_backend?
    # TODO: uri validation

    module NfsMountOptions
      HUMAN = N_('NFS mount options"):')
    end
    validates :nfs_mount_options,
              :presence => true,
              :if       => :nfs_backend?
    # TODO: mount options validation

    # TODO: add ceph UI parameters

    # TODO: add EqualLogic UI parameters


    def set_defaults
      self.driver_backend = DriverBackend::LVM
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
    # TODO: Add back CEPH and EQUALLOGIC as they're suppoirted
    def backend_labels_for_layout
      ret_list = DriverBackend::LABELS.clone
      ret_list.delete(DriverBackend::LVM) if self.deployment.ha?
      # TODO: remove this line when Ceph is supported
      ret_list.delete(DriverBackend::CEPH)
      # TODO: remove this line when EqualLogic is supported
      ret_list.delete(DriverBackend::EQUALLOGIC)

      ret_list
    end

  end
end
