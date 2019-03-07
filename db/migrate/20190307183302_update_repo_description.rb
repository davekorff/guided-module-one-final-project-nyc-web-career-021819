class UpdateRepoDescription < ActiveRecord::Migration[5.2]
  def change
    change_column :repos, :description, :string
  end
end
