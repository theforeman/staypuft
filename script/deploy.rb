User.current = User.first
deployment = Staypuft::Deployment.first

print 'Deploying ... '
result = ForemanTasks.trigger Actions::Staypuft::Deployment::Deploy, deployment

raise result.error unless result.triggered?
result.finished.value!

puts 'done.'
