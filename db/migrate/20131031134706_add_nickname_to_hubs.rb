class AddNicknameToHubs < ActiveRecord::Migration
  def change
    add_column :hubs, :nickname, :string
    add_column :hubs, :slug, :string
    add_index :hubs, :slug
  end
end
