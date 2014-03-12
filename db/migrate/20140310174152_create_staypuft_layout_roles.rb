class CreateStaypuftLayoutRoles < ActiveRecord::Migration
  def change
    create_table :staypuft_layout_roles do |t|
      t.references :layout, :null => false
      t.foreign_key :staypuft_layouts, column: :layout_id, :name => "staypuft_layout_roles_layout_id_fk"

      t.references :role, :null => false
      t.foreign_key :staypuft_roles, column: :role_id, :name => "staypuft_layout_roles_role_id_fk"

      t.timestamps
    end
    add_index :staypuft_layout_roles, :layout_id
    add_index :staypuft_layout_roles, :role_id
  end
end
