#encoding: utf-8
module Staypuft
  class Deployment::CinderService::Equallogic
    include ActiveModel::Serializers::JSON
    include ActiveModel::Validations
    extend ActiveModel::Naming

    attr_accessor :id, :san_ip, :san_login, :san_password, :pool, :group_name
    attr_reader :errors

    def initialize(attrs = {})
      @errors = ActiveModel::Errors.new(self)
      self.attributes = attrs
    end

    def self.human_attribute_name(attr, options = {})
      attr
    end

    def self.lookup_ancestors
      [self]
    end

    def attributes
      { 'san_ip' => nil, 'san_login' => nil, 'san_password' => nil, 'pool' => nil, 'group_name' => nil }
    end

    def attributes=(attrs)
      attrs.each { |attr, value| send "#{attr}=", value } unless attrs.nil?
    end

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
