class CreateStaypuftServices < ActiveRecord::Migration
  def change
    create_table :staypuft_services do |t|
      t.string :name,      :null => false
      t.text :description

      t.timestamps
    end
  end
end
