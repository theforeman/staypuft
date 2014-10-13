class AddValidationToSubnetTypes < ActiveRecord::Migration
  def change
    add_column :staypuft_subnet_types, :foreman_managed_ips, :boolean, :default => true
    add_column :staypuft_subnet_types, :default_to_provisioning, :boolean, :default => true
    add_column :staypuft_subnet_types, :dedicated_subnet, :boolean, :default => false
  end
end
