RSpec::Matchers.define_negated_matcher :not_contain, :include

def tag_lists_for(feed_items, context, sorted = false)
  lists = feed_items.map do |fi|
    fi_list = fi.all_tags_list_on(context)
    sorted ? fi_list.sort : fi_list
  end
  sorted ? lists.sort : lists
end
