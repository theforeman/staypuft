class CreateStaypuftSubnetTypings < ActiveRecord::Migration
  def change
    create_table :staypuft_subnet_typings do |t|
      t.references :deployment, :null => false
      t.references :subnet_type, :null => false
      t.references :subnet, :null => false

      t.timestamps
    end
    add_index :staypuft_subnet_typings, :deployment_id
    add_index :staypuft_subnet_typings, :subnet_type_id
    add_index :staypuft_subnet_typings, :subnet_id
  end
end
