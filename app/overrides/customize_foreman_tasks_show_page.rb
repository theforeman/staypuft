# older deface requires code prefix for erb tags
if Gem.loaded_specs['deface'].version >= Gem::Version.new('1.0.0')
  erb_tag = 'erb[loud]'
else
  erb_tag = 'code[erb-loud]'
end

Deface::Override.new(:virtual_path => "foreman_tasks/tasks/show",
                     :name => "add_return_to_deployment_button_to_foreman_tasks",
                     :insert_before => 'div.task-details',
                     :partial => "staypuft/deployments/deployment_progress_page_header"
                     )
