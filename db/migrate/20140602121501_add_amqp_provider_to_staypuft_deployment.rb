class AddAmqpProviderToStaypuftDeployment < ActiveRecord::Migration
  def change
    add_column :staypuft_deployments, :amqp_provider, :string

    Staypuft::Deployment.all.each do |deployment|
      deployment.amqp_provider = 'rabbitmq'
      deployment.save!
    end

    change_column :staypuft_deployments, :amqp_provider, :string, :null => false

  end
end
