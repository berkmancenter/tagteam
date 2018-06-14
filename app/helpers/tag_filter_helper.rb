# frozen_string_literal: true

module TagFilterHelper
  def filter_buttons
    [
      {
        role: :hub_tag_adder,
        data_type: 'AddTagFilter',
        text: 'Add a tag to all items in this hub',
        icon: 'plus-circle',
        button: 'success'
      },
      {
        role: :hub_tag_deleter,
        data_type: 'DeleteTagFilter',
        text: 'Remove a tag from every item in this hub',
        icon: 'minus-circle',
        button: 'danger'
      },
      {
        role: :hub_tag_modifier,
        data_type: 'ModifyTagFilter',
        text: 'Modify a tag for every item in this hub',
        icon: 'pencil',
        button: 'default'
      }
    ]
  end

  def filter_css_class(filter)
    case filter.class.name
    when 'AddTagFilter'
      'add'
    when 'ModifyTagFilter'
      'modify'
    when 'DeleteTagFilter'
      'delete'
    end
  end

  def filter_description(filter)
    case filter.class.name
    when 'AddTagFilter'
      'Add'
    when 'ModifyTagFilter'
      'Change'
    when 'DeleteTagFilter'
      'Delete'
    end
  end

  def self.split_tags(tags, hub)
    all_tags = []
    delimiters = hub.tags_delimiter_with_default

    # split by whitespace first
    whitespace_tags = tags.gsub(/\s+/m, ' ').gsub(/^\s+|\s+$/m, '').split(' ')

    # then split by the delimiter
    split_tags = whitespace_tags
    delimiters.each do |delimiter|
      arr = []
      split_tags.each do |tag|
        arr << tag.split(delimiter)
      end
      split_tags = arr.flatten.compact.uniq
    end

    split_tags
  end
end
