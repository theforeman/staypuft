module Staypuft
  class Deployment::CephService < Deployment::AbstractParamScope
    def self.param_scope
      'ceph'
    end

    param_attr :fsid, :volumes_key, :images_key


    class Jail < Safemode::Jail
      allow :fsid, :volumes_key, :images_key, :mon_initial_members
    end

    def set_defaults
      self.fsid = SecureRandom.uuid
      key = ` ceph-authtool --gen-print-key`
      key.chomp! if key
      self.volumes_key = key
      key = ` ceph-authtool --gen-print-key`
      key.chomp! if key
      self.images_key = key
    end

    def mon_initial_members
      fqdns = deployment.network_query.controller_fqdns.map {|fqdn| fqdn.split(".").first}
    end

    def param_hash
      { "fsid" => fsid, "volumes_key" => volumes_key, "images_key" => images_key }
    end

  end
end
