class FeedRetrieval < ActiveRecord::Base
  belongs_to :feed
  has_and_belongs_to_many :feed_items 

  scope :successful, where(['success is true'])

  after_save :update_feed_updated_at
  attr_accessor :changelog_summary_cache

  def update_feed_updated_at
    self.feed.updated_at = DateTime.now
    self.feed.save
  end

  def parsed_changelog
    # So here's where we'll parse the changelog to come up with a datastructure that makes sense. 
    changes = YAML.load(self.changelog)
  end

  def new_feed_items
    self.changelog_summary[:new_records]
  end

  def changed_feed_items
    self.changelog_summary[:changed_records]
  end

  def changelog_summary

    return self.changelog_summary_cache unless self.changelog_summary_cache.nil?

    changelog_yaml = parsed_changelog
    return nil if changelog_yaml.empty?
    changes = {
      :new_records => [],
      :changed_records => []
    }
    changelog_yaml.keys.each do|ch|
      if changelog_yaml[ch].include?(:new_record)
        changes[:new_records] << ch
      else
        # Something happened to this item
        # FIXME
        changed_fields = [ch]
        changelog_yaml[ch].keys.each do|change|
         changed_fields << change.to_s.titleize
        end
        changes[:changed_records] << changed_fields
      end
    end
    self.changelog_summary_cache = changes
    return changes
  end

end
