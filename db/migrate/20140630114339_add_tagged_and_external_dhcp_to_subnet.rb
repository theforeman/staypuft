class AddTaggedAndExternalDhcpToSubnet < ActiveRecord::Migration
  def change
    add_column :subnets, :tagged_communication, :boolean
    add_column :subnets, :external_dhcp, :boolean
  end
end
