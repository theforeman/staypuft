class AddAmqpProviderToStaypuftDeployment < ActiveRecord::Migration
  Deployment = Class.new(ActiveRecord::Base) do
    self.table_name = 'staypuft_deployments'
  end

  def change
    add_column :staypuft_deployments, :amqp_provider, :string

    Deployment.update_all :amqp_provider => 'rabbitmq'

    change_column :staypuft_deployments, :amqp_provider, :string, :null => false
  end
end
