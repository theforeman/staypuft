class CreateStaypuftDeployments < ActiveRecord::Migration
  def change
    create_table :staypuft_deployments do |t|
      t.string :name, :null => false
      t.text :description
      t.references :layout, :null => false
      t.foreign_key :staypuft_layouts, column: :layout_id, :name => "staypuft_deployments_layout_id_fk"

      t.references :hostgroup, :null => false
      t.foreign_key :hostgroups, :name => "staypuft_deployments_hostgroup_id_fk"

      t.timestamps
    end

    add_index :staypuft_deployments, :layout_id
  end
end
