module Staypuft
  class Deployment::GlanceService < Deployment::AbstractParamScope
    def self.param_scope
      'glance'
    end

    NFS_HELP = N_('(<server>:<local path>)')

    param_attr :driver_backend, :nfs_network_path

    module DriverBackend
      LOCAL   = 'local'
      NFS     = 'nfs'
      LABELS  = { LOCAL   => N_('Local File'),
                  NFS     => N_('NFS') }
      TYPES   = LABELS.keys
      HUMAN   = N_('Choose Driver Backend')
    end

    validates :driver_backend, presence: true, inclusion: { in: lambda {|g| g.backend_types_for_layout } }

    module NfsNetworkPath
      HUMAN       = N_('network path')
      HUMAN_AFTER = NFS_HELP
    end

    validates :nfs_network_path,
              :presence => true,
              :if       => :nfs_backend?
    # TODO: network_path validation

    class Jail < Safemode::Jail
      allow :driver_backend, :pcmk_fs_device, :pcmk_fs_options
    end

    def set_defaults
      self.driver_backend = DriverBackend::LOCAL
    end

    # gluster config only shows up for HA
    # glance UI is HA only until we add ceph (since there's only one option for non-HA)
    def active?
      deployment.ha?
    end

    def local_backend?
      self.driver_backend == DriverBackend::LOCAL
    end

    def nfs_backend?
      self.driver_backend == DriverBackend::NFS
    end

    def pcmk_fs_device
      if self.nfs_backend?
        self.nfs_network_path
      end
    end

    def pcmk_fs_options
      if self.nfs_backend?
        'context=\"system_u:object_r:glance_var_lib_t:s0\"'
      else
        ''
      end
    end

    # view should use this rather than DriverBackend::LABELS to hide LOCAL for HA.
    def backend_labels_for_layout
      ret_list = DriverBackend::LABELS.clone
      ret_list.delete(DriverBackend::LOCAL) if self.deployment.ha?
      ret_list
    end

    def backend_types_for_layout
      ret_list = DriverBackend::TYPES.clone
      ret_list.delete(DriverBackend::LOCAL) if self.deployment.ha?
      ret_list
    end

    def param_hash
      { "driver_backend" => driver_backend, "nfs_network_path" => nfs_network_path}
    end

  end
end
