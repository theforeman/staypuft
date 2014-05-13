class ChangeColumnDefaultFormStepOnStaypuftDeployment < ActiveRecord::Migration
  def up
    change_column :staypuft_deployments, :form_step, :string, :default => 'inactive', :null => false
  end
end
