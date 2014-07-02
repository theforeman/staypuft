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

    def check_box_f_non_inline(f, attr, options = {})
      text = options.delete(:text)
      checked_value = options.delete(:checked_value)
      unchecked_value = options.delete(:unchecked_value)
      content_tag(:div, :class => 'checkbox') do
        label_tag('') do
          f.check_box(attr, options, checked_value, unchecked_value) + " #{text} "
        end
      end
    end
  end
end
