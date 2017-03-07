class AddSignupReasonToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :signup_reason, :text
  end
end
