#encoding: utf-8
module Staypuft
  class Deployment::CinderService::Equallogic
    include ActiveModel::Serializers::JSON
    include ActiveModel::Validations
    extend ActiveModel::Naming

    attr_accessor :id, :san_ip, :san_login, :san_password, :pool, :group_name,
                  :thin_provision, :use_chap, :chap_login, :chap_password
    attr_reader :errors

    def initialize(attrs = {})
      @errors = ActiveModel::Errors.new(self)
      self.attributes = attrs
      self.thin_provision = false
      self.use_chap = false
      self.chap_login = ''
      self.chap_password = ''
    end

    def self.human_attribute_name(attr, options = {})
      attr
    end

    def self.lookup_ancestors
      [self]
    end

    def attributes
      { 'san_ip' => nil, 'san_login' => nil, 'san_password' => nil, 'pool' => nil,
        'group_name' => nil, 'thin_provision' => nil, 'use_chap' => nil,
        'chap_login' => nil, 'chap_password' => nil }
    end

    def attributes=(attrs)
      attrs.each { |attr, value| send "#{attr}=", value } unless attrs.nil?
    end

    class SanIpValueValidator < ActiveModel::EachValidator
      include Staypuft::Deployment::IpAddressValidator
    end

    validates :san_ip,
              presence: true,
              san_ip_value: true
    validates :san_login,
              presence: true,
              format: /\A[a-zA-Z\d][\w\.\-]*[\w\-]\z/,
              length: { maximum: 16 }
    validates :san_password,
              presence: true,
              format: /\A[!-~]+\z/,
              length: { minimum:3, maximum: 16 }
    validates :pool,
              presence: true,
              format: /\A[[^\p{Z}\p{C}!"\#$%&'\(\)\*\+,\/;<=>\?@\[\]\\\^\{\}|~\.\-:]][[^\p{Z}\p{C}!"\#$%&'\(\)\*\+,\/;<=>\?@\[\]\\\^\{\}|~]]+[[^\p{Z}\p{C}!"\#$%&'\(\)\*\+,\/;<=>\?@\[\]\\\^\{\}|~\.\-:]]\z/,
              length: { maximum: 63,
                             too_long: "Too long: max length is %{count} bytes. Using multibyte characters reduces the maximum number of characters allowed.",
                             tokenizer: lambda {|str| str.bytes.to_a } }
    validates :group_name,
              presence: true,
              format: /\A[a-zA-Z\d][a-zA-Z\d\-]*\z/,
              length: { maximum: 54 }
  end
end
