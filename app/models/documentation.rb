# frozen_string_literal: true
# In-app documentation linked contextually via the ApplicationHelper#documentation helper.
#
# Most validations are contained in the ModelExtensions mixin.
#
class Documentation < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions
  before_validation do
    auto_sanitize_html(:description)
  end

  validates :match_key, uniqueness: true
  attr_accessible :id, :match_key, :title, :description, :lang, :created_at, :updated_at

  def display_title
    title.blank? ? match_key : title
  end
  alias to_s display_title

  def self.title
    'Documentation'
  end
end
