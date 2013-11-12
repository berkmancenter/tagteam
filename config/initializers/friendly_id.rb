FriendlyId.defaults do |config|
  config.use :reserved
  # Reserve words for English and Spanish URLs
  config.reserved_words = %w(new edit meta list request_rights contact community add_roles remove_roles retrievals background_activity bookmark_collections by_date all_items items index my my_bookmark_collections item_search search)
end
