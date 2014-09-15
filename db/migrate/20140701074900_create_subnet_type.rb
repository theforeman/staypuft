class CreateSubnetType < ActiveRecord::Migration
  def change
    create_table :staypuft_subnet_types do |t|
      t.string :name,      :null => false

      t.timestamps
    end
  end
end
