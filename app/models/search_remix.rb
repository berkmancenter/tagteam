# frozen_string_literal: true
class SearchRemix < ApplicationRecord
  has_many :input_sources, dependent: :destroy, as: :item_source
  belongs_to :hub, optional: true
  attr_accessible :search_string, :hub
  validates :search_string, presence: true

  def to_s
    "Search for '#{search_string}'"
  end

  def url_key
    "search_for_#{search_string.parameterize('_')}"
  end

  def default_remix_title
    "Remix of search: #{search_string}"
  end

  def self.search_results_for(search_remix_id, limit = 150)
    s = find search_remix_id

    search = FeedItem.search do
      with :hub_ids, s.hub.id
      fulltext s.search_string
      order_by('date_published', :desc)
      # This is a little bit of a hack, but we need to get as many
      # feed items that match as possible for the remix feed.
      paginate page: 1, per_page: limit
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
    '<span class="ui-silk inline ui-silk-magnifier"></span>'
  end
end
