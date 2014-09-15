# older deface requires code prefix for erb tags
if Gem.loaded_specs['deface'].version >= Gem::Version.new('1.0.0')
  erb_tag = 'erb[loud]'
else
  erb_tag = 'code[erb-loud]'
end

Deface::Override.new(:virtual_path => "hosts/_form",
                     :name => "include_custom_js_for_hosts_edit",
                     :insert_after => "erb[loud]:contains('form_for')",
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
