# encoding: utf-8
module Staypuft
  class Deployment::CinderService < Deployment::AbstractParamScope
    def self.param_scope
      'cinder'
    end

    BACKEND_TYPE_PARAMS = :backend_eqlx, :backend_nfs, :backend_lvm, :backend_ceph
    BACKEND_PARAMS = :nfs_uri, :rbd_secret_uuid

    param_attr *BACKEND_TYPE_PARAMS, *BACKEND_PARAMS
    param_attr_array :eqlxs => Equallogic

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
    validate :at_least_one_backend_selected

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
    module SanLogin
      HUMAN       = N_('SAN Login:')
    end
    module SanPassword
      HUMAN       = N_('SAN Password:')
    end
    module EqlxPool
      HUMAN       = N_('Pool:')
    end
    module EqlxGroupName
      HUMAN       = N_('Group:')
    end
    validates :eqlxs,
              :presence   => true,
              :if         => :equallogic_backend?
    validate :equallogic_backends

    class Jail < Safemode::Jail
      allow :lvm_backend?, :nfs_backend?, :ceph_backend?, :equallogic_backend?,
        :multiple_backends?, :rbd_secret_uuid, :nfs_uri, :eqlxs, :eqlxs_attributes=,
        :compute_eqlx_san_ips, :compute_eqlx_san_logins, :compute_eqlx_san_passwords,
        :compute_eqlx_group_names, :compute_eqlx_pools
    end

    def set_defaults
      self.backend_lvm = "false"
      self.backend_ceph = "false"
      self.backend_nfs = "false"
      self.backend_eqlx = "false"
      self.rbd_secret_uuid = SecureRandom.uuid
    end

    # cinder config always shows up
    def active?
      true
    end

    def lvm_backend?
      !self.deployment.ha? && self.backend_lvm == "true"
    end

    def nfs_backend?
      self.backend_nfs == "true"
    end

    def ceph_backend?
      self.backend_ceph == "true"
    end

    def equallogic_backend?
      self.backend_eqlx == "true"
    end

    def multiple_backends?
      (equallogic_backend? and self.eqlxs.length > 1) or
        BACKEND_TYPE_PARAMS.select { |type| send(type.to_s) == "true" }.length > 1
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
      { "backend_lvm" => backend_lvm, "backend_ceph" => backend_ceph,
        "backend_nfs" => backend_nfs, "backend_eqlx" => backend_eqlx,
        "nfs_uri" => nfs_uri, "rbd_secret_uuid" => rbd_secret_uuid,
        "eqlxs" => self.eqlxs }
    end

    def lvm_ptable
      Ptable.find_by_name('LVM with cinder-volumes')
    end

    %w{san_ip san_login san_password group_name pool}.each do |name|
      define_method "compute_eqlx_#{name}s" do
        self.eqlxs.collect { |e| e.send name }
      end
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

    def at_least_one_backend_selected
      params = BACKEND_TYPE_PARAMS.clone
      params.delete :backend_lvm if self.deployment.ha?
      unless params.detect(lambda { false }) { |field| self.send(field) == "true" }
        errors.add :base, _("At least one storage backend must be selected")
      end
    end

    def equallogic_backends
      unless self.eqlxs.all? { |item| item.valid? }
        errors.add :base, _("Please fix the problems in selected backends")
      end
    end
  end
end
