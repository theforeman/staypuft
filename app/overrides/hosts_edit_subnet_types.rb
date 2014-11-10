# older deface requires code prefix for erb tags
if Gem.loaded_specs['deface'].version >= Gem::Version.new('1.0.0')
  erb_tag = 'erb[loud]'
else
  erb_tag = 'code[erb-loud]'
end

Deface::Override.new(:virtual_path => "nic/_base_form",
                     :name => "add_network_types_to_subnet_on_nic",
                     :replace => "#{erb_tag}:contains(':subnet_id')",
                     :template => "nic/_subnet_id_field")

Deface::Override.new(:virtual_path => "hosts/_unattended",
                     :name => "add_network_types_to_subnet_on_primary_interface",
                     :replace => "span#subnet_select",
                     :template => "hosts/_primary_interface_subnet")

Deface::Override.new(:virtual_path => "hosts/_unattended",
                     :name => "add_network_types_to_subnet_on_new_nic_form",
                     :replace => "#{erb_tag}:contains('new_child_fields_template')",
                     :template => "hosts/_new_nic_fields")
