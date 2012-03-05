class CreateRoles < ActiveRecord::Migration

  def change
    create_table :roles, :force => true do |t|
      t.string   :name,              :limit => 40
      t.string   :authorizable_type, :limit => 40
      t.integer  :authorizable_id
      t.timestamps
    end
    [:name,:authorizable_type, :authorizable_id].each do|col|
      add_index :roles, col
    end

    create_table :roles_users, :id => false, :force => true do |t|
      t.references  :user
      t.references  :role
#      t.timestamps
    end
    [:user_id, :role_id].each do|col|
      add_index :roles_users, col
    end
  end

end
