class AddRoleToStaypuftDeploymentRoleHostgroup < ActiveRecord::Migration
  def change
    add_column :staypuft_deployment_role_hostgroups, :role_id, :integer
    add_column :staypuft_deployment_role_hostgroups, :deploy_order, :integer

    add_foreign_key :staypuft_deployment_role_hostgroups,  :staypuft_roles, column: :role_id, :name => "staypuft_deployment_role_hostgroups_role_id_fk"

    change_column :staypuft_deployment_role_hostgroups, :role_id, :integer, :null => false
    change_column :staypuft_deployment_role_hostgroups, :deploy_order, :integer, :null => false
  end
end
