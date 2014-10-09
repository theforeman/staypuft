class AddCustomReposToDeployment < ActiveRecord::Migration
  def change
    add_column :staypuft_deployments, :custom_repos, :text
  end
end
