class AddNicknameToHubs < ActiveRecord::Migration[4.2]
  def change
    add_column :hubs, :nickname, :string
    add_column :hubs, :slug, :string
    add_index :hubs, :slug
  end
end
