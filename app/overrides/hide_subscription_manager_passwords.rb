# older deface requires code prefix for erb tags
if Gem.loaded_specs['deface'].version >= Gem::Version.new('1.0.0')
  erb_tag = 'erb[loud]'
else
  erb_tag = 'code[erb-loud]'
end

Deface::Override.new(:virtual_path => "common_parameters/_inherited_parameters",
                     :name => "hide_subscription_manager_passwords",
                     :surround => 'td.col-md-7 ' + erb_tag + ':contains("parameter_value_field inherited_parameters[name]")',
                     :original => '<%= parameter_value_field inherited_parameters[name] %>',
                     :text => "<% if name == 'subscription_manager_password' %>*****<% else %><%= render_original %><% end %>"
                     )
