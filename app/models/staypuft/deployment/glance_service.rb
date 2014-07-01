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
      GLUSTER = 'gluster'
      LABELS  = { LOCAL   => N_('Local File'),
                  NFS     => N_('NFS'),
                  GLUSTER => N_('Gluster') }
      TYPES   = LABELS.keys
      HUMAN   = N_('Choose Driver Backend')
    end

    validates :driver_backend, presence: true, inclusion: { in: DriverBackend::TYPES }

    module NfsNetworkPath
      HUMAN       = N_('network path')
      HUMAN_AFTER = '(server:localpath)'
    end

    validates :nfs_network_path,
              :presence => true,
              :if       => :nfs_backend?
    # TODO: network_path validation

    module GlusterNetworkPath
      HUMAN       = N_('primary server (network path)')
      HUMAN_AFTER = '(server:localpath)'
    end

    validates :gluster_network_path,
              :presence => true,
              :if       => :gluster_backend?
    # TODO: network_path validation

    module GlusterBackupVolfileServers
      HUMAN       = N_('additional servers')
      HUMAN_AFTER = '(server1:server2:etc)'
    end

    #validates :gluster_backup_volfile_servers,
    #          :if           => :gluster_backend?
    # TODO: backup_volfile_servers validation

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

    def gluster_backend?
      self.driver_backend == DriverBackend::GLUSTER
    end

    def network_path
      if self.nfs_backend?
        self.nfs_network_path
      elsif self.gluster_backend?
        self.gluster_network_path
      end
    end

    def pcmk_fs_device
      network_path.split(':')[0] if network_path
    end

    def pcmk_fs_dir
      network_path.split(':')[1] if network_path
    end

    def pcmk_fs_options
      if self.nfs_backend?
        "context=\"system_u:object_r:glance_var_lib_t:s0\")"
      elsif self.gluster_backend?
        unless self.gluster_backup_volfile_servers.blank?
          "selinux,backup-volfile-servers#{backup_volfile_servers}"
        else
          "selinux"
        end
      end
    end

    # view should use this rather than DriverBackend::LABELS to hide LOCAL for HA.
    def backend_labels_for_layout
      ret_list = DriverBackend::LABELS.clone
      ret_list.delete(DriverBackend::LOCAL) if self.deployment.ha?
      ret_list
    end

  end
end
