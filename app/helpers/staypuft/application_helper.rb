module Staypuft
  module ApplicationHelper
    def radio_button_f_non_inline(f, attr, options = {})
      text = options.delete(:text)
      value = options.delete(:value)
      content_tag(:div, :class => 'radio') do
        label_tag('') do
          f.radio_button(attr, value, options) + " #{text} "
        end
      end
    end
  end
end
