class CreateStaypuftLayouts < ActiveRecord::Migration
  def change
    create_table :staypuft_layouts do |t|
      t.string :name,      :null => false
      t.text :description

      t.timestamps
    end
  end
end
