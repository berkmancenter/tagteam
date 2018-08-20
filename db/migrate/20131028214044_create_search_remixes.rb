class CreateSearchRemixes < ActiveRecord::Migration[4.2]
  def change
    create_table :search_remixes do |t|
      t.integer :hub_id
      t.text :search_string

      t.timestamps
    end
  end
end
