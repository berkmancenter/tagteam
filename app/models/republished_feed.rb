class RepublishedFeed < ActiveRecord::Base

  include AuthUtilities
  include ModelExtensions

  acts_as_authorization_object
  SORTS = ['date_published', 'title']
  SORTS_FOR_SELECT = [['Date Published','date_published' ],['Title', 'title']]
  MIXING_STRATEGIES = ['interlaced','date']
  MIXING_STRATEGIES_FOR_SELECT = [['Interlaced','interlaced'],['Date','date']]

  belongs_to :hub
  has_many :input_sources, :dependent => :destroy, :order => :position 

  attr_accessible :title, :hub_id, :description, :default_sort, :mixing_strategy, :limit

  def item_search

    add_feeds = []
    add_feed_items = []
    add_tags = []

    remove_feeds = []
    remove_feed_items = []
    remove_tags = []

    if self.input_sources.blank?
      return nil
    end

    self.input_sources.each do|input_source|
      if input_source.effect == 'add'
        if input_source.item_source_type == 'Feed'
          add_feeds << input_source.item_source_id

        elsif input_source.item_source_type == 'FeedItem'
          add_feed_items << input_source.item_source_id

        else
          add_tags << input_source.item_source_id
        end

      else
        if input_source.item_source_type == 'Feed'
          remove_feeds << input_source.item_source_id

        elsif input_source.item_source_type == 'FeedItem'
          remove_feed_items << input_source.item_source_id

        else
          remove_tags << input_source.item_source_id
        end

      end
    end

    (sort_column,order) = (self.default_sort == 'title') ? ['title', :asc] : ['date_published', :desc]

    search = FeedItem.search(:include => [:tags,:taggings,:feeds]) do
      any_of do
        unless add_feeds.blank?
          with(:feed_ids, add_feeds)
        end
        unless add_feed_items.blank?
          with(:id, add_feed_items)
        end
        unless add_tags.blank?
          with(:tag_contexts, add_tags.collect{|t| "hub_#{self.hub_id}-#{t}"})
        end
      end
      any_of do
        unless remove_feeds.blank?
          without(:feed_ids, remove_feeds)
        end
        unless remove_feed_items.blank?
          without(:id, remove_feed_items)
        end
        unless remove_tags.blank?
          without(:tag_contexts, remove_tags.collect{|t| "hub_#{self.hub_id}-#{t}"})
        end
      end
      order_by(sort_column, order)
    end

    search

  end

  def old_items
    #here's where we'll iterate through input_sources, add or subtract them and come to a final list of items.
    # This is currently VERY inefficient and will not scale well when there are many input sources and/or feed items
    items = []
    self.input_sources.each do|input_source|
      if input_source.effect == 'add'
        items << input_source.item_source.items(self.hub)
      end
    end
    output_items = items.flatten.uniq.compact

    self.input_sources.each do|input_source|
      if input_source.effect == 'remove'
        output_items = output_items - input_source.item_source.items(self.hub)
      end
    end

    output_items = output_items.sort_by{|i| (self.default_sort == 'date_published') ? i.date_published : i.title}
    if self.default_sort == 'date_published'
      output_items.reverse!
    end
    # DANGER, WILL ROBINSON! Inefficient. 
    output_items[0..self.limit]
  end

  def to_s
    "#{title}"
  end

end
