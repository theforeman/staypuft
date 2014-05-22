# older deface requires code prefix for erb tags
if Gem.loaded_specs['deface'].version >= Gem::Version.new('1.0.0')
  erb_tag = 'erb[loud]'
else
  erb_tag = 'code[erb-loud]'
end

Deface::Override.new(:virtual_path => "common_parameters/_inherited_parameters",
                     :name => "hide_subscription_manager_passwords_in_host_form",
                     :surround => 'td.col-md-7 ' + erb_tag + ':contains("parameter_value_field inherited_parameters[name]")',
                     :original => '<%= parameter_value_field inherited_parameters[name] %>',
                     :text => "<% if name == 'subscription_manager_password' %>*****<% else %><%= render_original %><% end %>"
                     )

Deface::Override.new(:virtual_path => "common_parameters/_parameter",
                     :name => "hide_subscription_manager_passwords_in_parameter_form",
                     :surround => 'td.col-md-7 ' + erb_tag + %q(:contains('f.text_area(:value, :class => "form-control", :rows => line_count(f, :value), :disabled => (not authorized_via_my_scope("host_editing", "edit_params")), :placeholder => _("Value"))')),
                     :original => '<%= f.text_area(:value, :class => "form-control", :rows => line_count(f, :value), :disabled => (not authorized_via_my_scope("host_editing", "edit_params")), :placeholder => _("Value")) %>',
                     :text => "<% if f.object.name == 'subscription_manager_password' %><%= f.password_field :value, :class => 'form-control', :disabled => (not authorized_via_my_scope('host_editing', 'edit_params')), :value => f.object.value %><% else %><%= render_original %><% end %>"
                     )


Deface::Override.new(:virtual_path => "common_parameters/index",
                     :name => "hide_subscription_manager_passwords_on_index",
                     :surround => 'td ' + erb_tag + ':contains("trunc(common_parameter.safe_value, 80)")',
                     :original => '<%= trunc(common_parameter.safe_value, 80) %>',
                     :text => "<% if common_parameter.name == 'subscription_manager_password' %>*****<% else %><%= render_original %><% end %>"
                     )

Deface::Override.new(:virtual_path => "common_parameters/_form",
                     :name => "hide_subscription_manager_passwords_in_form",
                     :surround => erb_tag + %q(:contains('text_f f, :value, :size => "col-md-8"')),
                     :original => '<%= text_f f, :value, :size => "col-md-8" %>',
                     :text => "<% if @common_parameter.name == 'subscription_manager_password' %><%= password_f f, :value, :size => 'col-md-8', :value => @common_parameter.value %><% else %><%= render_original %><% end %>"
                     )
