class AddDeployOrderToStaypuftLayoutRole < ActiveRecord::Migration
  def change
    add_column :staypuft_layout_roles, :deploy_order, :integer
    change_column :staypuft_layout_roles, :deploy_order, :integer, :null => false
  end
end
