class CreateStaypuftRoleServices < ActiveRecord::Migration
  def change
    create_table :staypuft_role_services do |t|
      t.references :service,  :null => false
      t.foreign_key :service, :name => "staypuft_role_servicess_service_id_fk"

      t.references :role,     :null => false
      t.foreign_key :role,    :name => "staypuft_role_servicess_role_id_fk"

      t.timestamps
    end
    add_index :staypuft_role_services, :service_id
    add_index :staypuft_role_services, :role_id
  end
end
