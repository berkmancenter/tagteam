# A FeedRetrieval tracks the results of the spidering of a Feed. It contains a YAML changelog of new or changed FeedItem objects, and some representation of what actually changed.
#
# FeedItem change tracking is used to calculate the spidering schedule for a Feed, and could be used in the future to calculate metrics and do some interesting analysis about what's getting posted when.  More on how scheduling works can be found in the Feed class.
#
class FeedRetrieval < ActiveRecord::Base
  belongs_to :feed
  has_and_belongs_to_many :feed_items, join_table: 'feed_items_feed_retrievals'
  has_many :hubs, through: :feed

  scope :successful, -> { where(success: true) }

  # Find the HubFeed for this FeedRetrieval within a Hub. A Feed can live in multiple hubs, so this slightly contorted method is needed to find how this FeedRetrieval relates in the context of a Hub.
  def hub_feed_for_hub(hub = Hub.first)
    feed.hub_feeds.reject { |hf| hf.hub_id != hub.id }.first
  end

  after_save :update_feed_updated_at
  attr_accessor :changelog_summary_cache
  attr_accessible :feed_id, :success, :status_code
  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end

  api_accessible :default do |t|
    t.add :feed
    t.add :hubs
    t.add :status_code
    t.add :created_at
    t.add :updated_at
    t.add :success
    t.add :new_feed_items
    t.add :changed_feed_items
  end

  searchable do
    integer :feed_id
    integer :hub_ids, multiple: true
    boolean :success
    string :status_code
    time :updated_at
  end

  # We've got changes, so updates the updated_at value for the actual feed this FeedRetrieval references.
  def update_feed_updated_at
    feed.updated_at = DateTime.current
    feed.save
  end

  # de-YAMLize the changelog back into ruby objects.
  def parsed_changelog
    return nil if changelog.nil?
    # TODO: determine how to handle symbols in changelogs using YAML.safe_load
    YAML.load(changelog)
  end

  # Extract the new FeedItem ids from the changelog.
  def new_feed_items
    changelog_summary[:new_records]
  end

  # Extract the changed FeedItem ids from the changelog.
  def changed_feed_items
    changelog_summary[:changed_records]
  end

  # Returns true if this FeedRetrieval has resulted in FeedItems with changes.
  def has_changes?
    new_feed_items.blank? && changed_feed_items.blank? ? false : true
  end

  # Return a simple data structure of changes in this FeedRetrieval, if any. Use a simple in-object attribute cache to avoid parsing the same, non-changing YAML more than once per method call.
  def changelog_summary
    return changelog_summary_cache unless changelog_summary_cache.nil?

    changelog_yaml = parsed_changelog
    changes = {
      new_records: [],
      changed_records: []
    }

    return changes if changelog_yaml.nil?

    changelog_yaml.keys.each do |ch|
      if changelog_yaml[ch].include?(:new_record)
        changes[:new_records] << ch
      else
        # Something happened to this item
        # FIXME
        changed_fields = [ch]
        changelog_yaml[ch].keys.each do |change|
          changed_fields << change.to_s.titleize
        end
        changes[:changed_records] << changed_fields
      end
    end
    self.changelog_summary_cache = changes
    changes
  end

  def display_title
    created_at.to_s
  end

  alias to_s display_title

  def self.title
    'Feed update'
  end
end
