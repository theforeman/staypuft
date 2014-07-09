module Staypuft::Concerns::LookupKeyExtensions
  extend ActiveSupport::Concern

  included do
    alias_method_chain :cast_validate_value, :erb
    alias_method_chain :value_before_type_cast, :limpet

    # apply only when this extension is included
    ::Staypuft::Concerns::LookupKeyExtensions.monkey_path_safe_render
  end

  LIMPET_FORMAT        = '<%%={key_id:%s};'
  LIMPET_FORMAT_REGEXP = /#{LIMPET_FORMAT % '(\d+)'}/

  def cast_validate_value_with_erb(value)
    if has_erb? value
      if value =~ LIMPET_FORMAT_REGEXP
        value.gsub(/#{LIMPET_FORMAT_REGEXP}/, LIMPET_FORMAT % id)
      else
        value.gsub(/<%=/, LIMPET_FORMAT % id)
      end
    else
      cast_validate_value_without_erb value
    end
  end

  def cast_validate_value_after_erb(value, type)
    method = "cast_value_#{type}".to_sym
    return value unless self.respond_to? method, true
    self.send(method, value) rescue raise TypeError
  end

  def self.has_erb?(value)
    value =~ /<%.*%>/
  end

  def has_erb?(value)
    Staypuft::Concerns::LookupKeyExtensions.has_erb? value
  end

  def self.evaluate_value(hostgroup, value)
    host = Host::Managed.new(hostgroup: hostgroup, name: 'renderer')
    SafeRender.new(:variables => { :host => host }).parse(value)
  rescue => e
    "ERROR: #{e.message} (#{e.class})"
  end

  def value_before_type_cast_with_limpet(value)
    value_before_type_cast_without_limpet(value).tap do |v|
      v.gsub!(LIMPET_FORMAT_REGEXP, '<%=') if has_erb? v
    end
  end

  def self.monkey_path_safe_render
    ::SafeRender.class_eval do
      def parse_string(string)
        raise ::ForemanException.new(N_('SafeRender#parse_string was passed a %s instead of a string') % string.class) unless string.is_a? String

        lookup_key_id = string[Staypuft::Concerns::LookupKeyExtensions::LIMPET_FORMAT_REGEXP, 1]
        if lookup_key_id
          lookup_key = LookupKey.find(lookup_key_id)
          type       = lookup_key.key_type
        end

        value = if Setting[:safemode_render]
                  box = Safemode::Box.new self, @allowed_methods
                  box.eval(ERB.new(string, nil, '-').src, @allowed_vars)
                else
                  @allowed_vars.each { |k, v| instance_variable_set "@#{k}", v }
                  ERB.new(string, nil, '-').result(binding)
                end

        if type
          lookup_key.cast_validate_value_after_erb value, type
        else
          value
        end
      end
    end
  end
end

