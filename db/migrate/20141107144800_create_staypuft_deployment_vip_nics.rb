class CreateStaypuftDeploymentVipNics < ActiveRecord::Migration
  def change
    create_table :staypuft_deployment_vip_nics do |t|
      t.references :deployment, :null => false
      t.foreign_key :staypuft_deployments, column: :deployment_id, :name => "staypuft_deployment_vip_nic_deployment_id_fk"

      t.references :vip_nic, :null => false
      t.foreign_key :nics, column: :vip_nic_id, :name => "staypuft_deployment_vip_nics_nic_id_fk"

      t.timestamps
    end
    add_index :staypuft_deployment_vip_nics, :deployment_id
    add_index :staypuft_deployment_vip_nics, :vip_nic_id
  end
end
