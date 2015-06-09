RSpec::Matchers.define :show_effects_of do |filter|
  match do |tag_lists|
    case filter.class.name
    when 'AddTagFilter'
      tag_lists.all? { |tag_list| tag_list.include? filter.tag.name }
    when 'ModifyTagFilter'
      old_tag = filter.tag.name
      new_tag = filter.new_tag.name
      return false if tag_lists.any?{ |tag_list| tag_list.include? old_tag }
      return false if tag_lists.none?{ |tag_list| tag_list.include? new_tag }
      true
    when 'DeleteTagFilter'
      tag_lists.none?{ |tag_list| tag_list.include? filter.tag.name }
    end
  end

  failure_message do |tag_lists|
    case filter.class.name
    when 'AddTagFilter'
      "expected #{tag_lists} to all include '#{filter.tag.name}'"
    when 'ModifyTagFilter'
      "expected at least one instance of '#{filter.new_tag.name}' " +
      "and zero instances of '#{filter.tag.name}', but got #{tag_lists}"
    when 'DeleteTagFilter'
      "expected #{tag_lists} to never include '#{filter.tag.name}'"
    end
  end
end

RSpec::Matchers.define_negated_matcher :not_contain, :include
RSpec::Matchers.define_negated_matcher :not_show_effects_of, :show_effects_of

def tag_lists_for(feed_items, context, sorted = false)
  lists = feed_items.map do |fi|
    fi_list = fi.all_tags_list_on(context)
    sorted ? fi_list.sort : fi_list
  end
  sorted ? lists.sort : lists
end
