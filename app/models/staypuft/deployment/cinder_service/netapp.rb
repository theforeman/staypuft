#encoding: utf-8
module Staypuft
  class Deployment::CinderService::Netapp
    include ActiveModel::Serializers::JSON
    include ActiveModel::Validations
    extend ActiveModel::Naming

    attr_accessor :id, :hostname, :login, :password, :server_port,
                  :storage_family, :transport_type, :storage_protocol,
                  :nfs_shares_config, :volume_list, :vfiler, :vserver,
                  :controller_ips, :sa_password, :storage_pools
    attr_reader :errors

    STORAGE_FAMILIES = { :ontap_cluster => 'Clustered Data ONTAP',
                         :ontap_7mode => 'Data ONTAP 7-mode',
                         :eseries => 'E-Series' }
    STORAGE_PROTOCOLS = { :nfs => 'NFS', :iscsi => 'iSCSI' }
    TRANSPORT_TYPES = { :http => 'http', :https => 'https' }

    def initialize(attrs = {})
      @errors = ActiveModel::Errors.new(self)
      self.attributes = attrs
      self.server_port = 80
      self.storage_family = 'ontap_cluster'
      self.transport_type = 'http'
      self.storage_protocol = 'nfs'
    end

    def self.human_attribute_name(attr, options = {})
      attr
    end

    def self.lookup_ancestors
      [self]
    end

    def attributes
      { 'hostname' => nil, 'login' => nil, 'password' => nil,
        'server_port' => nil, 'storage_family' => nil, 'transport_type' => nil,
        'storage_protocol' => nil, 'nfs_shares_config' => nil,
        'volume_list' => nil, 'vfiler' => nil, 'vserver' => nil,
        'controller_ips' => nil, 'sa_password' => nil,
        'storage_pools' => nil }
    end

    def attributes=(attrs)
      attrs.each { |attr, value| send "#{attr}=", value } unless attrs.nil?
    end

    validates :login,
              presence: true,
              format: /\A[a-zA-Z\d][\w\.\-]*[\w\-]\z/,
              length: { maximum: 16 }
    validates :password,
              presence: true,
              format: /\A[!-~]+\z/,
              length: { minimum:3, maximum: 16 }
  end
end
