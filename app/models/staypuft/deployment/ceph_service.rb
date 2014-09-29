module Staypuft
  class Deployment::CephService < Deployment::AbstractParamScope
    def self.param_scope
      'ceph'
    end

    param_attr :fsid, :volumes_key, :images_key, :osd_pool_size, :osd_journal_size


    class Jail < Safemode::Jail
      allow :fsid, :volumes_key, :images_key, :mon_initial_members,
            :osd_pool_size, :osd_journal_size
    end

    def set_defaults
      self.fsid = SecureRandom.uuid
      key = ` ceph-authtool --gen-print-key`
      key.chomp! if key
      self.volumes_key = key
      key = ` ceph-authtool --gen-print-key`
      key.chomp! if key
      self.images_key = key
      self.osd_pool_size = ''
      self.osd_journal_size = ''
    end

    def mon_initial_members
      fqdns = deployment.network_query.controller_fqdns.map {|fqdn| fqdn.split(".").first}
    end

    def param_hash
      { "fsid" => fsid, "volumes_key" => volumes_key, "images_key" => images_key,
        "osd_pool_size" => osd_pool_size, "osd_journal_size" => osd_journal_size }
    end

  end
end
