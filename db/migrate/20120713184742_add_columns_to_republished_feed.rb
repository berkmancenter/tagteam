class AddColumnsToRepublishedFeed < ActiveRecord::Migration[4.2]
  def change
    add_column :republished_feeds, :url_key, :string, :limit => 50.bytes

    RepublishedFeed.all.each do |rp|
      rp.url_key = rp.title.downcase.gsub(/[^a-z\d]/,'-')
      rp.save
    end

    # Now add the not-null constraint after creating the url_keys
    change_column :republished_feeds, :url_key, :string, :limit => 50.bytes, :null => false

    add_index :republished_feeds, :url_key, :unique => true
  end
end
