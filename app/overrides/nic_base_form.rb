# older deface requires code prefix for erb tags
if Gem.loaded_specs['deface'].version >= Gem::Version.new('1.0.0')
  erb_tag = 'erb[loud]'
else
  erb_tag = 'code[erb-loud]'
end

Deface::Override.new(:virtual_path => "nic/_base_form",
                     :name => "add_network_types_to_subnet",
                     :replace => "erb[loud]:contains(':subnet_id')",
                     :template => "nic/_subnet_id_field")
