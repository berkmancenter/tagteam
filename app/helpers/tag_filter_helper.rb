module TagFilterHelper
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
end
