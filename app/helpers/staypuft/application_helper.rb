module Staypuft
  module ApplicationHelper

    def subtitle(page_subtitle)
      content_for(:subtitle, page_subtitle.to_s)
    end

    def tabbed_nav_menu(menu_items, id=nil, class_name=nil, subclass_name=nil)
      content_tag(:ul, :class => class_name, :id => id) do
        menu_items.each do | item |
          concat(content_tag(:li, link_to(item[:title], "#{item[:target_id]}",
                                          :class => subclass_name,
                                          :data => { :id => item[:target_id], :toggle => 'tab'}),
                                          :class => item[:active] ? "#{item[:class]} active" : item[:class] ))
        end
      end
    end

    def radio_button_f_non_inline(f, attr, options = {})
      text  = options.delete(:text)
      value = options.delete(:value)
      content_tag(:div, :class => 'radio') do
        label_tag('') do
          f.radio_button(attr, value, options) + " #{text} "
        end
      end
    end

    def check_box_f_non_inline(f, attr, options = {})
      text            = options.delete(:text)
      checked_value   = options.delete(:checked_value)
      unchecked_value = options.delete(:unchecked_value)
      content_tag(:div, :class => 'checkbox') do
        label_tag('') do
          f.check_box(attr, options, checked_value, unchecked_value) + " #{text} "
        end
      end
    end

    def change_label_width(width, html)
      html.gsub(/class="col-md-2 control-label"/, "class=\"col-md-#{width} control-label\"").html_safe
    end
  end
end
