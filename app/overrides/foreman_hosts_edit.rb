# older deface requires code prefix for erb tags
if Gem.loaded_specs['deface'].version >= Gem::Version.new('1.0.0')
  erb_tag = 'erb[loud]'
else
  erb_tag = 'code[erb-loud]'
end

Deface::Override.new(:virtual_path => "hosts/_form",
                     :name => "include_custom_js_for_hosts_edit",
                     :insert_after => "li > a[href='#network']",
                     :text => "<%= javascript 'staypuft/host_edit'%>"
                     )

Deface::Override.new(:virtual_path => "hosts/_form",
                     :name => "add_fencing_tab_to_hosts_edit",
                     :insert_after => "li > a[href='#network']",
                     :text => "<li><a href='#fencing' data-toggle='tab'><%= _('Fencing') %></a></li>"
                     )

Deface::Override.new(:virtual_path => "hosts/_unattended",
                     :name => "add_fencing_form_to_hosts_edit",
                     :insert_after => "#network",
                     :text => "<div class='tab-pane' id='fencing'><%= render 'hosts/fencing', :host => @host, :f => f %></div>"
                     )

Deface::Override.new(:virtual_path => "hosts/_form",
                     :name => "remove_openstack_hostgroups",
                     :replace => "#{erb_tag}:contains(':hostgroup_id')",
                     :original => '04903c858c6f96ed5c015cac5960e02708d8fea8'
                     ) do
"       <% hostgroups = accessible_hostgroups.reject { |hg| hg.to_label =~ /\#{Setting[:base_hostgroup]}\\/.*/ && hg.to_label != @host.hostgroup.to_label } %>
        <%=  select_f f, :hostgroup_id, hostgroups, :id, :to_label,
          { :include_blank => true},
          { :onchange => 'hostgroup_changed(this);', :'data-host-id' => @host.id,
            :'data-url' => (@host.new_record? || @host.type_changed?) ? process_hostgroup_hosts_path : hostgroup_or_environment_selected_hosts_path,
            :help_inline => :indicator } %>
"
end
