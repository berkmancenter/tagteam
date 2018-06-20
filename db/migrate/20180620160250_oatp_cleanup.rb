class OatpCleanup < ActiveRecord::Migration[5.1]
  def change
    execute 'UPDATE feed_items_feeds SET feed_id = 3868 WHERE feed_id = 1362'
    execute 'DELETE FROM hub_feeds WHERE id = 1793'
    execute 'UPDATE feed_items_feeds SET feed_id = 3183 WHERE feed_id = 11133'
    execute 'DELETE FROM hub_feeds WHERE id = 3360'
    execute 'UPDATE feed_items_feeds SET feed_id = 1558 WHERE feed_id = 1538'
    execute 'DELETE FROM hub_feeds WHERE id = 1797'
  end
end
