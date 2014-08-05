# encoding: utf-8
module Staypuft
  class Deployment::CinderService < Deployment::AbstractParamScope
    def self.param_scope
      'cinder'
    end

    param_attr :driver_backend, :nfs_uri, :rbd_secret_uuid,
               :san_ip, :san_login, :san_password, :eqlx_group_name, :eqlx_pool
    after_save :set_lvm_ptable

    class SanIpValueValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)        
        return if value.empty?

        begin
          ip_addr = IPAddr.new(value)
          ip_range = ip_addr.to_range
          if ip_range.begin == ip_range.end
            true
          else
            record.errors.add attribute, "Specify single IP address, not range"
            false
          end
        rescue
          # not IP addr
          # validating as fqdn
          if /(?=^.{1,254}$)(^(((?!-)[a-zA-Z0-9-]{1,63}(?<!-))|((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63})$)/ =~ value
            true
          else
            record.errors.add attribute, "Invalid IP address or FQDN supplied"
            false
          end
        end
      end
    end

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
              :presence     => true,
              :if           => :equallogic_backend?,
              :san_ip_value => true
    # FIXME: Currently this only validates IP addresses, however hostnames are valid here
    # too. In the absence of "IP or hostname" validation, is forcing IP only better than
    # no validation, or should we disable this until it works for all valid values?

    module SanLogin
      HUMAN       = N_('SAN Login:')
    end
    # Up to 16 alphanumeric characters, including period, hyphen, and underscore.
    # First character must be a letter or number.  Last character cannot be a period.
    # ASCII, Not Unicode
    validates :san_login,
              :presence => true,
              :format   => /\A[a-zA-Z\d][\w\.\-]*[\w\-]\z/,
              :length   => { maximum: 16 },
              :if       => :equallogic_backend?

    module SanPassword
      HUMAN       = N_('SAN Password:')
    end
    # Password must be 3 to 16 printable ASCII characters and is case-sensitive.
    # Punctuation characters are allowed, but spaces are not.
    # Only the first 8 characters are used, the rest are ignored (without a message).
    # ASCII, Not Unicode
    validates :san_password,
              :presence => true,
              :format   => /\A[!-~]+\z/,
              :length   => { minimum:3, maximum: 16 },
              :if       => :equallogic_backend?

    module EqlxPool
      HUMAN       = N_('Pool:')
    end
    # Name can be up to 63 bytes and is case insensitive.
    # You can use any printable Unicode character except for
    # ! " # $ % & ' ( ) * + , / ; < = > ?@ [ \ ] ^ _ ` { | } ~.
    # First and last characters cannot be a period, hyphen, or colon.
    # Fewer characters are accepted for this field if you enter the value as a
    # Unicode character string, which takes up a variable number of bytes,
    # depending on the specific character.
    # ASCII, Unicode
    validates :eqlx_pool,
              :presence => true,
              :format   => /\A[[^\p{Z}\p{C}!"#$%&'\(\)\*\+,\/;<=>\?@\[\]\\\^\{\}|~\.\-:]][[^\p{Z}\p{C}!"#$%&'\(\)\*\+,\/;<=>\?@\[\]\\\^\{\}|~]]+[[^\p{Z}\p{C}!"#$%&'\(\)\*\+,\/;<=>\?@\[\]\\\^\{\}|~\.\-:]]\z/,
              :length   => { maximum: 63,
                             too_long: "Too long: max length is %{count} bytes. Multbyte characters reduce the maximum number of characters available.",
                             tokenizer: lambda {|str| str.bytes.to_a } },
              :if       => :equallogic_backend?

    module EqlxGroupName
      HUMAN       = N_('Group:')
    end
    # Up to 54 alphanumeric characters and hyphens(dashes).
    # The first character must be a letter or a number.
    # ASCII, Not Unicode
    validates :eqlx_group_name,
              :presence => true,
              :format   => /\A[a-zA-Z\d][a-zA-Z\d\-]*\z/,
              :length   => { maximum: 54 },
              :if       => :equallogic_backend?

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
        "san_ip" => san_ip, "san_login" => san_login, "san_password" => san_password,
        "eqlx_group_name" => eqlx_group_name, "eqlx_pool" => eqlx_pool }
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
