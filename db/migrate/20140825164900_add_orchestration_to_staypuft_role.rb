class AddOrchestrationToStaypuftRole < ActiveRecord::Migration
  def change
    add_column :staypuft_roles, :orchestration, :string
  end
end
