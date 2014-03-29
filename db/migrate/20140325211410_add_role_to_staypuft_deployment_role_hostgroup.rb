class AddRoleToStaypuftDeploymentRoleHostgroup < ActiveRecord::Migration
  module Staypuft
    class DeploymentRoleHostgroup < ActiveRecord::Base
      self.table_name = 'staypuft_deployment_role_hostgroups'
    end
    class HostgroupRole < ActiveRecord::Base
      self.table_name = 'staypuft_hostgroup_roles'
    end
  end

  def change
    add_column :staypuft_deployment_role_hostgroups, :role_id, :integer
    add_column :staypuft_deployment_role_hostgroups, :deploy_order, :integer

    add_foreign_key :staypuft_deployment_role_hostgroups,  :staypuft_roles, column: :role_id, :name => "staypuft_deployment_role_hostgroups_role_id_fk"

    Staypuft::DeploymentRoleHostgroup.all.each do |drh|
      hg_role = Staypuft::HostgroupRole.where(:hostgroup_id=>drh.hostgroup_id).first!
      drh.role_id = hg_role.role_id
      drh.deploy_order = 1
      drh.save!
    end

    change_column :staypuft_deployment_role_hostgroups, :role_id, :integer, :null => false
    change_column :staypuft_deployment_role_hostgroups, :deploy_order, :integer, :null => false
  end
end
