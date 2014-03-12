class CreateStaypuftRoleClasses < ActiveRecord::Migration
  def change
    create_table :staypuft_role_classes do |t|
      t.references :role, :null => false
      t.foreign_key :staypuft_roles, column: :role_id, :name => "staypuft_role_classes_role_id_fk"

      t.references :puppetclass, :null => false
      t.foreign_key :puppetclasses, :name => "staypuft_role_classes_puppetclass_id_fk"

      t.timestamps
    end
    add_index :staypuft_role_classes, :role_id
    add_index :staypuft_role_classes, :puppetclass_id
  end
end
