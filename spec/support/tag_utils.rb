RSpec::Matchers.define_negated_matcher :not_contain, :include
RSpec::Matchers.define :be_consistent_with do |filter|
  match do |tag_lists|
    case filter.filter.class.name
    when 'AddTagFilter'
      tag_lists.all? { |tag_list| tag_list.include? filter.filter.tag.name }
    when 'ModifyTagFilter'
      old_tag = filter.filter.tag.name
      return false if tag_lists.any?{ |tag_list| tag_list.include? old_tag }
    when 'DeleteTagFilter'
    end
  end

  failure_message do |tag_lists|
    case filter.filter.class.name
    when 'AddTagFilter'
      "expected #{tag_lists} to all include '#{filter.filter.tag.name}'"
    when 'ModifyTagFilter'
      "expected #{tag_lists} to all include '#{filter.filter.tag.name}'"
    when 'DeleteTagFilter'
      "expected #{tag_lists} to all include '#{filter.filter.tag.name}'"
    end
  end
end

def tag_lists_for(feed_items, context, sorted = false)
  lists = feed_items.map do |fi|
    fi_list = fi.all_tags_list_on(context)
    sorted ? fi_list.sort : fi_list
  end
  sorted ? lists.sort : lists
end
