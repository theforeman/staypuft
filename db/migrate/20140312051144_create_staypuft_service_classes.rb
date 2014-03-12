class CreateStaypuftServiceClasses < ActiveRecord::Migration
  def change
    create_table :staypuft_service_classes do |t|
      t.references :service, :null => false
      t.foreign_key :staypuft_services, column: :service_id, :name => "staypuft_service_classes_service_id_fk"

      t.references :puppetclass, :null => false
      t.foreign_key :puppetclasses, :name => "staypuft_service_classes_puppetclass_id_fk"

      t.timestamps
    end
    add_index :staypuft_service_classes, :service_id
    add_index :staypuft_service_classes, :puppetclass_id
  end
end
