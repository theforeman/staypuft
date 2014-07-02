module Staypuft
  class Deployment::GlanceService < Deployment::AbstractParamScope
    def self.param_scope
      'glance'
    end

    param_attr :driver_backend, :nfs_network_path, :gluster_network_path,
               :gluster_backup_volfile_servers

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
      HUMAN_AFTER = '(server:localpath)'
    end

    validates :nfs_network_path,
              :presence => true,
              :if       => :nfs_backend?
    # TODO: network_path validation

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

    def network_path
      if self.nfs_backend?
        self.nfs_network_path
      end
    end

    def pcmk_fs_device
      network_path.nil? ? '' : network_path.split(':')[0]
    end

    def pcmk_fs_dir
      network_path.nil? ? '' : network_path.split(':')[1]
    end

    def pcmk_fs_options
      if self.nfs_backend?
        "context=\"system_u:object_r:glance_var_lib_t:s0\")"
      else
        ""
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

  end
end
