class CreateLayoutSubnet < ActiveRecord::Migration
  def change
    create_table :staypuft_layout_subnet_types do |t|
      t.references :layout, :null => false
      t.references :subnet_type, :null => false

      t.timestamps
    end
  end
end
