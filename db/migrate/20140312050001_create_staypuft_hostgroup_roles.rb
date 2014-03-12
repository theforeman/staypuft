class CreateStaypuftHostgroupRoles < ActiveRecord::Migration
  def change
    create_table :staypuft_hostgroup_roles do |t|
      t.references :role,  :null => false
      t.foreign_key :role, :name => "staypuft_hostgroup_roles_role_id_fk"

      t.references :hostgroup,  :null => false
      t.foreign_key :hostgroup, :name => "staypuft_hostgroup_roles_hostgroup_id_fk"

      t.timestamps
    end
    add_index :staypuft_hostgroup_roles, :role_id
    add_index :staypuft_hostgroup_roles, :hostgroup_id
  end
end
