class CreateTagFilters < ActiveRecord::Migration
  class HubTagFilter < ActiveRecord::Base
  end

  class HubFeedTagFilter < ActiveRecord::Base
  end

  class HubFeedItemTagFilter < ActiveRecord::Base
  end

  def up
    create_table :tag_filters do |t|
      t.references :hub, null: false
      t.references :tag, null: false
      t.references :new_tag
      t.references :scope, polymorphic: true

      t.boolean :applied, default: false
      t.string :type
      t.timestamps
    end
    add_index :tag_filters, :hub_id
    add_index :tag_filters, :tag_id
    add_index :tag_filters, :new_tag_id
    add_index :tag_filters, [:scope_type, :scope_id]
    add_index :tag_filters, :type

    def translate_filter(filter, scope)
      new_filter = TagFilter.create(
        hub: filter.hub,
        scope: scope,
        tag: filter.filter.tag,
        new_tag: filter.filter.new_tag,
        type: filter.filter_type,
        applied: true,
        updated_at: filter.updated_at
      )

      filter.owners.each do |owner|
        owner.has_role! :owner, new_filter
      end
      filter.creators.each do |creator|
        creator.has_role! :creator, new_filter
      end
    end


    HubTagFilter.unscoped.order('updated_at ASC').each do |filter|
      translate_filter(filter, filter.hub)
    end

    HubFeedTagFilter.unscoped.order('updated_at ASC').each do |filter|
      translate_filter(filter, filter.hub_feed)
    end

    HubFeedItemTagFilter.unscoped.order('updated_at ASC').each do |filter|
      translate_filter(filter, filter.feed_item)
    end

    drop_table :hub_tag_filters
    drop_table :hub_feed_tag_filters
    drop_table :hub_feed_item_tag_filters
    drop_table :add_tag_filters
    drop_table :modify_tag_filters
    drop_table :delete_tag_filters
  end

  def down
    # Figuring out how to revert this is a waste of time right now.
    raise ActiveRecord::IrreversibleMigration
  end
end
