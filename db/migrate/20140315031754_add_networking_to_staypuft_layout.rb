class AddNetworkingToStaypuftLayout < ActiveRecord::Migration
  def change
    add_column :staypuft_layouts, :networking, :string
  end
end
