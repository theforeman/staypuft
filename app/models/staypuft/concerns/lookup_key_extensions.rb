module Staypuft::Concerns::LookupKeyExtensions
  extend ActiveSupport::Concern

  included do
    alias_method_chain :cast_validate_value, :erb
    alias_method_chain :default_value_before_type_cast, :limpet
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

  def has_erb? value
    value =~ /<%.*%>/
  end

  def default_value_before_type_cast_with_limpet
    default_value_before_type_cast_without_limpet.gsub(LIMPET_FORMAT_REGEXP,'<%=')
  end
end

# MONKEY
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

