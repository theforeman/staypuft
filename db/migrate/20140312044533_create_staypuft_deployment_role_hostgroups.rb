class CreateStaypuftDeploymentRoleHostgroups < ActiveRecord::Migration
  def change
    create_table :staypuft_deployment_role_hostgroups do |t|
      t.references :deployment, :null => false
      t.foreign_key :staypuft_deployments, column: :deployment_id, :name => "staypuft_deployment_role_hostgroups_deployment_id_fk"

      t.references :hostgroup, :null => false
      t.foreign_key :hostgroups, :name => "staypuft_deployment_role_hostgroups_hostgroup_id_fk"

      t.timestamps
    end
    add_index :staypuft_deployment_role_hostgroups, :deployment_id
    add_index :staypuft_deployment_role_hostgroups, :hostgroup_id
  end
end
