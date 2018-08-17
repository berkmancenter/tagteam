# frozen_string_literal: true

module TagFilterHelper
  def filter_buttons
    [
      {
        role: :hub_tag_adder,
        data_type: 'AddTagFilter',
        text: 'Add a tag to every item in this hub',
        icon: 'plus-circle',
        button: 'success',
        extra_class: 'force_confirm'
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
      },
      {
        role: :hub_tag_supplementer,
        data_type: 'SupplementTagFilter',
        text: 'Supplement a tag with a second tag for every item in this hub',
        icon: 'plus-circle',
        button: 'primary'
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
    when 'SupplementTagFilter'
      'supplement'
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
    when 'SupplementTagFilter'
      'Supplement'
    end
  end

  def self.split_tags(tags, hub)
    # Replace multiple whitespace with single whitespace
    all_tags = [tags.gsub(/\s+/m, ' ')]

    hub.tags_delimiter.each do |delimiter|
      new_tags = []
      all_tags.each do |tag|
        new_tags << (delimiter == '⎵' ? tag.split(/\s/) : tag.split(delimiter))
      end
      all_tags = new_tags.flatten.delete_if { |a| a.blank? }
    end

    all_tags
  end
end
