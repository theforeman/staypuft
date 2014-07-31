module Staypuft
  class Deployment::CinderService < Deployment::AbstractParamScope
    def self.param_scope
      'cinder'
    end

    param_attr :driver_backend, :nfs_uri, :rbd_secret_uuid,
               :san_ip, :san_login, :san_password, :eqlx_group_name, :eqlx_pool
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

    module SanIp
      HUMAN       = N_('SAN IP Addr:')
    end
    validates :san_ip,
              :presence => true,
              :if       => :equallogic_backend?
    # TODO: IP address validation
    # FIXME: question -- should this be validated explicitly as an IP address,
    #                    or would a dns-resolvable hostname also be appropriate?

    module SanLogin
      HUMAN       = N_('SAN Login:')
    end
    validates :san_login,
              :presence => true,
              :if       => :equallogic_backend?
    # TODO: Login validation

    module SanPassword
      HUMAN       = N_('SAN Password:')
    end
    validates :san_password,
              :presence => true,
              :if       => :equallogic_backend?

    module EqlxPool
      HUMAN       = N_('Pool:')
    end
    validates :eqlx_pool,
              :presence => true,
              :if       => :equallogic_backend?
    # TODO: pool validation

    module EqlxGroupName
      HUMAN       = N_('Group:')
    end
    validates :eqlx_group_name,
              :presence => true,
              :if       => :equallogic_backend?
    # TODO: group name validation

    class Jail < Safemode::Jail
      allow :lvm_backend?, :nfs_backend?, :nfs_uri, :ceph_backend?, :equallogic_backend?,
        :rbd_secret_uuid, :san_ip, :san_login, :san_password, :eqlx_group_name, :eqlx_pool
    end

    def set_defaults
      self.driver_backend  = DriverBackend::LVM
      self.rbd_secret_uuid = SecureRandom.uuid
      self.san_login       = 'grpadmin'
      self.eqlx_pool       = 'default'
      self.eqlx_group_name = 'group-0'
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
    def backend_labels_for_layout
      ret_list = DriverBackend::LABELS.clone
      ret_list.delete(DriverBackend::LVM) if self.deployment.ha?
      ret_list
    end
    def backend_types_for_layout
      ret_list = DriverBackend::TYPES.clone
      ret_list.delete(DriverBackend::LVM) if self.deployment.ha?
      ret_list
    end

    def param_hash
      { "driver_backend" => driver_backend, "nfs_uri" => nfs_uri,
        "rbd_secret_uuid" => rbd_secret_uuid,
        "san_ip" => san_ip, "san_login" => san_login, "san_password" => san_password }
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
