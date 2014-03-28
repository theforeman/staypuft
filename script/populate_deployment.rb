User.current = User.first

deployment       = Staypuft::Deployment.first
compute_resource = ComputeResource.find_by_name!(ENV['COMPUTE_RESOURCE'] || 'Libvirt')
hostgroups       = deployment.child_hostgroups

puts 'clean up old hosts'
hostgroups.each do |hostgroup|
  hostgroup.hosts.each do |host|
    print "destroying #{host.name} ... "
    host.destroy
    puts 'done.'
  end
end

puts 'creating new ones'
hostgroups.each do |hostgroup|
  result = ForemanTasks.trigger(Actions::Staypuft::Host::Create, name = rand(1000).to_s,
                                hostgroup, compute_resource, start: false)
  print "creating #{name} ... "
  raise result.error unless result.triggered?
  result.finished.value!
  puts 'done.'

  # TODO set networks
end
