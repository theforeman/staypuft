# encoding: utf-8
module Staypuft
  class Deployment::CinderService < Deployment::AbstractParamScope
    def self.param_scope
      'cinder'
    end

    BACKEND_TYPE_PARAMS = :backend_eqlx, :backend_nfs, :backend_lvm, :backend_ceph, :backend_netapp
    BACKEND_PARAMS = :nfs_uri, :rbd_secret_uuid

    param_attr *BACKEND_TYPE_PARAMS, *BACKEND_PARAMS
    param_attr_array :eqlxs => Equallogic
    param_attr_array :netapps => Netapp

    after_save :set_lvm_ptable

    module DriverBackend
      LVM        = 'lvm'
      NFS        = 'nfs'
      CEPH       = 'ceph'
      EQUALLOGIC = 'equallogic'
      NETAPP     = 'netapp'
      LABELS     = { LVM        => N_('LVM'),
                     NFS        => N_('NFS'),
                     CEPH       => N_('Ceph'),
                     EQUALLOGIC => N_('EqualLogic'),
                     NETAPP     => N_('NetApp') }
      TYPES      = LABELS.keys
      HUMAN      = N_('Choose Driver Backend')
    end
    validate :at_least_one_backend_selected

    module NfsUri
      HUMAN       = N_('NFS URI:')
      HUMAN_AFTER = Deployment::GlanceService::NFS_HELP
    end

    class NfsUriValueValidator < ActiveModel::EachValidator
      include Staypuft::Deployment::NfsUriValidator
    end

    validates :nfs_uri,
              :presence      => true,
              :if            => :nfs_backend?,
              :nfs_uri_value => true

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
    validate :equallogic_backends,
             :if          => :equallogic_backend?

    module NetappHostname
      HUMAN   = N_('Hostname:')
    end
    module NetappLogin
      HUMAN   = N_('Login:')
    end
    module NetappPassword
      HUMAN   = N_('Password:')
    end
    module NetappServerPort
      HUMAN   = N_('Server Port:')
    end
    module NetappStorageFamily
      HUMAN   = N_('Storage Family:')
    end
    module NetappTransportType
      HUMAN   = N_('Transport Type:')
    end
    module NetappStorageProtocol
      HUMAN   = N_('Storage Protocol:')
    end
    module NetappNfsShares
      HUMAN   = N_('NFS Shares:')
    end
    module NetappNfsSharesConfig
      HUMAN   = N_('NFS Shares Config:')
    end
    module NetappVolumeList
      HUMAN   = N_('Volume List:')
    end
    module NetappVfiler
      HUMAN   = N_('vFiler:')
    end
    module NetappVserver
      HUMAN   = N_('Storage Virtual Machine (SVM):')
    end
    module NetappControllerIps
      HUMAN   = N_('Controller IPs:')
    end
    module NetappSaPassword
      HUMAN   = N_('SA Password:')
    end
    module NetappStoragePools
      HUMAN   = N_('Storage Pools:')
    end

    validates :netapps,
              :presence   => true,
              :if         => :netapp_backend?
    validate :netapp_backends,
             :if          => :netapp_backend?

    class Jail < Safemode::Jail
      allow :lvm_backend?, :nfs_backend?, :ceph_backend?, :equallogic_backend?, :netapp_backend?,
        :multiple_backends?, :rbd_secret_uuid, :nfs_uri, :eqlxs, :eqlxs_attributes=,
        :compute_eqlx_san_ips, :compute_eqlx_san_logins, :compute_eqlx_san_passwords,
        :compute_eqlx_group_names, :compute_eqlx_pools, :compute_eqlx_thin_provision,
        :compute_eqlx_use_chap, :compute_eqlx_chap_logins, :compute_eqlx_chap_passwords,
        :netapps, :compute_netapp_hostnames, :compute_netapp_logins, :compute_netapp_passwords,
        :compute_netapp_server_ports, :compute_netapp_storage_familys,
        :compute_netapp_transport_types, :compute_netapp_storage_protocols,
        :compute_netapp_nfs_shares, :compute_netapp_nfs_shares_configs, :compute_netapp_volume_lists,
        :compute_netapp_vfilers, :compute_netapp_vservers, :compute_netapp_controller_ips,
        :compute_netapp_sa_passwords, :compute_netapp_storage_pools
    end

    def set_defaults
      self.backend_lvm = "false"
      self.backend_ceph = "false"
      self.backend_nfs = "false"
      self.backend_eqlx = "false"
      self.backend_netapp = "false"
      self.rbd_secret_uuid = SecureRandom.uuid
    end

    # cinder config always shows up
    def active?
      true
    end

    def lvm_backend?
      self.backend_lvm == "true"
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

    def netapp_backend?
      self.backend_netapp == "true"
    end

    def multiple_backends?
      (equallogic_backend? and self.eqlxs.length > 1) or
        (netapp_backend? and self.netapps.length > 1) or
        BACKEND_TYPE_PARAMS.select { |type| send(type.to_s) == "true" }.length > 1
    end

    def backend_labels_for_layout
      DriverBackend::LABELS
    end
    def backend_types_for_layout
      DriverBackend::TYPES
    end

    def param_hash
      { "backend_lvm" => backend_lvm, "backend_ceph" => backend_ceph,
        "backend_nfs" => backend_nfs, "backend_eqlx" => backend_eqlx,
        "nfs_uri" => nfs_uri, "rbd_secret_uuid" => rbd_secret_uuid,
        "eqlxs" => self.eqlxs, "backend_netapp" => backend_netapp,
        "netapps" => self.netapps }
    end

    def lvm_ptable
      Ptable.find_by_name('LVM with cinder-volumes')
    end

    %w{san_ip san_login san_password group_name pool chap_login chap_password}.each do |name|
      define_method "compute_eqlx_#{name}s" do
        self.eqlxs.collect { |e| e.send name }
      end
    end

    %w{thin_provision use_chap}.each do |name|
      define_method "compute_eqlx_#{name}" do
        self.eqlxs.collect { |e| e.send name }
      end
    end

    %w{hostname login password server_port storage_family transport_type
       storage_protocol nfs_shares_config volume_list vfiler vserver
       sa_password }.each do |name|
      define_method "compute_netapp_#{name}s" do
        self.netapps.collect { |e| e.send name }
      end
    end

    %w{controller_ips storage_pools}.each do |name|
      define_method "compute_netapp_#{name}" do
        self.netapps.collect { |e| e.send name }
      end
    end

    # We need to split the NFS share by comma since puppet-cinder
    # is expecting an array of shares instead of just a comma
    # separated list.  .split() splits up the string by commas
    # and .reject() removes any empty elements in the resulting array
    %w{nfs_shares}.each do |name|
      define_method "compute_netapp_#{name}" do
        self.netapps.collect { |e| e.send(name).split(',').reject(&:empty?) }
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
      unless BACKEND_TYPE_PARAMS.detect(lambda { false }) { |field| self.send(field) == "true" }
        errors.add :base, _("At least one storage backend must be selected")
      end
    end

    def equallogic_backends
      unless self.eqlxs.all? { |item| item.valid? }
        errors.add :base, _("Please fix the problems in selected backends")
      end
    end

    def netapp_backends
      unless self.netapps.all? { |item| item.valid? }
        errors.add :base, _("Please fix the problems in selected backends")
      end
    end
  end
end
