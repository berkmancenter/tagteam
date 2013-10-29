class SearchRemix < ActiveRecord::Base
  has_many :input_sources, :dependent => :destroy, :as => :item_source
  belongs_to :hub
  attr_accessible :search_string, :hub
  validates_presence_of :search_string

  def to_s
    "Search for '#{self.search_string}'"
  end

  def self.search_results_for(search_remix_id)
    s = find search_remix_id

    search = FeedItem.search do
      with :hub_ids, s.hub.id
      fulltext s.search_string
      adjust_solr_params do |params|
        params[:q].gsub! '#', "tag_contexts_sm:#{s.hub.tagging_key}-"
      end
    end

    search.execute!
    search.results.collect(&:id)
  rescue ActiveRecord::RecordNotFound
    []
  end

  def mini_icon
    %q|<span class="ui-silk inline ui-silk-application-view-list"></span>|
  end
end
