Deface::Override.new(:virtual_path => "common_parameters/_inherited_parameters",
                     :name => "hide_subscription_manager_passwords",
                     :surround => 'td.col-md-7 erb[loud]:contains("parameter_value_field inherited_parameters[name]")',
                     :original => '<%= parameter_value_field inherited_parameters[name] %>',
                     :text => "<% if name == 'subscription_manager_password' %>*****<% else %><%= render_original %><% end %>"
                     )

