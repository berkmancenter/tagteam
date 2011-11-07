class FeedRetrieval < ActiveRecord::Base
  belongs_to :feed
  has_and_belongs_to_many :feed_items 

  scope :successful, where(['success is true'])

  after_save :update_feed_updated_at

  def update_feed_updated_at
    self.feed.updated_at = DateTime.now
    self.feed.save
  end

  def parsed_changelog
    # So here's where we'll parse the changelog to come up with a datastructure that makes sense. 
    changes = YAML.load(self.changelog)
  end

  def changelog_summary
    changelog_yaml = parsed_changelog
    return nil if changelog_yaml.empty?

    changes = {
      :new_records => 0,
      :changed_fields => []
    }

    changelog_yaml.keys.each do|ch|
      if changelog_yaml[ch].include?(:new_record)
        changes[:new_records] = changes[:new_records] + 1
      else
        # Something happened to this item
        # FIXME
        changelog_yaml[ch].keys.each do|change|
          changes[:changed_fields] << change.to_s.titleize
        end
      end
    end
    return changes
  end

end
