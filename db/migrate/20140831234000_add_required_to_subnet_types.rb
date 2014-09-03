class AddRequiredToSubnetTypes < ActiveRecord::Migration
  def change
    add_column :staypuft_subnet_types, :is_required, :boolean, :default => true
  end
end
