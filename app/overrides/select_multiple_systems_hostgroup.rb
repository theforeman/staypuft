# older deface requires code prefix for erb tags
if Gem.loaded_specs['deface'].version >= Gem::Version.new('1.0.0')
  erb_tag = 'erb[loud]'
else
  erb_tag = 'code[erb-loud]'
end

Deface::Override.new(:virtual_path => "hosts/select_multiple_hostgroup",
                     :name => "remove_openstack_hostgroups_multiple",
                     :replace => "#{erb_tag}:contains(':id')",
                     :original => '<%= selectable_f f, :id, [[_("Select host group"),"disabled"],[_("*Clear host group*"), "" ]] + Hostgroup.all.map{|h| [h.to_label, h.id]}.sort,{}, :onchange => "toggle_multiple_ok_button(this)" %>'
                     ) do
"  <%= selectable_f f, :id, [[_(\"Select host group\"),\"disabled\"],[_(\"*Clear host group*\"), \"\" ]] + Hostgroup.all.reject{ |hg| hg.to_label =~ /\#{Setting[:base_hostgroup]}\\/.*/ }.map{|h| [h.to_label, h.id]}.sort,{},
        :onchange => \"toggle_multiple_ok_button(this)\" %>"
end
