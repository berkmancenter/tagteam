ActsAsTaggableOn::Tag.class_eval do

  after_initialize do |tag|
    name.try(:strip!)
  end
  
  def count_by_hub(hub)
    FeedItem.tagged_with(name, :on => hub.tagging_key.to_s).uniq.size
  end
  
  def self.find_or_create_by_name_normalized(name)
    self.find_or_create_by_name(self.normalize_name(name))
  end

  def self.find_by_name_normalized(name)
    self.find_by_name(self.normalize_name(name))
  end

  def self.normalize_name(name)
    name.to_s.mb_chars.downcase[0, 255].gsub(/,/, '_').strip
  end

  def contexts
    #contexts = ActsAsTaggableOn::Tagging.select('context').where('tag_id = ? and context != ?',self.id,'tags').group('context')
    contexts = self.taggings.collect{|tg| tg.context}.reject{|ct| ct == 'tags'}
    (contexts.length == 0) ? [] : contexts 
  end

  def name_prefixed_with(prefix = '')
    (self.name[0..(prefix.length - 1)] == prefix) ? self.name : "#{prefix}#{self.name}"
  end

  def hub_ids
    self.contexts.collect{|c| c.split('_')[1].to_i}.flatten.uniq
  end

  def mini_icon
    %q|<span class="ui-silk inline ui-silk-tag-blue"></span>|
  end

  def items(hub = Hub.first)
    taggings.find(:all, :include => [:taggable], :conditions => {:context => hub.tagging_key.to_s}, :order => 'created_at desc').collect{|tg| tg.taggable}
  end

end

ActsAsTaggableOn::Tag.instance_eval do
  has_many :add_tag_filters
  has_many :modify_tag_filters
  has_many :delete_tag_filters
  has_many :input_sources, :dependent => :destroy, :as => :item_source

  acts_as_api do|c|
    c.allow_jsonp_callback = true
  end

  api_accessible :default do |t|
    t.add :id
    t.add :name
  end

  searchable do
    text :name
    integer :hub_ids, :multiple => true
    string :contexts, :multiple => true
    string :name
  end

  def title
    "#{name}"
  end

  def self.title
    "Tag"
  end
end

ActsAsTaggableOn::Tagging.class_eval do
  def deactivates_taggings(items: taggable)
    items = [items] unless items.respond_to? :map
    self.class.where(tag_id: tag_id, context: context,
                     taggable_id: items.map(&:id), taggable_type: 'FeedItem')
  end
end

ActsAsTaggableOn::Tagging.instance_eval do
  include TaggingDeactivator
end

ActsAsTaggableOn::Taggable.class_eval do
  def first_use_of_tag_in_context(tag, context)
    tagged_with(tag, :on => context).order("created_at").limit(1).first.created_at
  end
end
