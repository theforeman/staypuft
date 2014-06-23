class RemoveAmqpProviderFromStaypuftDeployment < ActiveRecord::Migration
  def change
    remove_column :staypuft_deployments, :amqp_provider
    # TODO(pitr) migrate down?
  end
end
