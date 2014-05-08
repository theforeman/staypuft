class AddFormStepToStaypuftDeployment < ActiveRecord::Migration
  def change
    add_column :staypuft_deployments, :form_step, :string
  end
end
