class AddUsernameToUsers < ActiveRecord::Migration

  def self.up
    add_column :users, :username, :string, :limit => 150
    add_index :users, :username, :unique => true 
    User.all.each do|u|
      u.username = u.email.split('@')[0]
      u.save
    end
  end

  def self.down
    remove_column :users, :username
  end

end
