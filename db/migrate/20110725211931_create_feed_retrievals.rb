class CreateFeedRetrievals < ActiveRecord::Migration
  def self.up
    create_table :feed_retrievals do |t|
      t.integer :feed_id
      t.string :url
      t.string :content
      t.boolean :success
      t.string :status_code

      t.timestamps
    end
  end

  def self.down
    drop_table :feed_retrievals
  end
end
