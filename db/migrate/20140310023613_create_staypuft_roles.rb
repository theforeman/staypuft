class CreateStaypuftRoles < ActiveRecord::Migration
  def change
    create_table :staypuft_roles do |t|
      t.string :name,      :null => false
      t.text :description
      t.integer :min_hosts
      t.integer :max_hosts

      t.timestamps
    end
  end
end
