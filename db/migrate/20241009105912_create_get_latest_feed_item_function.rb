class CreateGetLatestFeedItemFunction < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE FUNCTION get_latest_feed_item(feed_id_param INTEGER)
      RETURNS TABLE(id INTEGER, title VARCHAR, url VARCHAR, guid VARCHAR, authors VARCHAR, contributors VARCHAR, description VARCHAR, content VARCHAR, rights VARCHAR, date_published TIMESTAMP, last_updated TIMESTAMP, created_at TIMESTAMP, updated_at TIMESTAMP, image_url TEXT) AS $$
      BEGIN
          RETURN QUERY
          WITH relevant_feed_items AS (
            SELECT feed_item_id
            FROM feed_items_feeds
            WHERE feed_id = feed_id_param
          )
          SELECT fi.*
          FROM feed_items fi
          JOIN relevant_feed_items rfi ON fi.id = rfi.feed_item_id
          ORDER BY fi.date_published DESC
          LIMIT 1;
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION IF EXISTS get_latest_feed_item(INTEGER);
    SQL
  end
end
