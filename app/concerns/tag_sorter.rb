class TagSorter
  SORT_OPTS = %w(alpha frequency created_at)
  def initialize(args)
    @tags = args[:tags]
    raise "No tags supplied" if @tags.blank?

    @sort_by = args[:sort_by].to_s
    raise "No sort option supplied" if @sort_by.blank?
    raise "Invalid sort option: please use #{SORT_OPTS.join(" or ")}" unless SORT_OPTS.include?(@sort_by)

    @context = args[:context]
    @klass = args[:class]
    raise "Must supply context to sort by date created" if @sort_by == "created_at" and @context.blank?
    raise "Must supply class to sort by date created" if @sort_by == "created_at" and @klass.blank?
  end

  def sort
    case @sort_by
    when "alpha"
      sort_by_alpha
    when "frequency"
      sort_by_frequency
    when "created_at"
      sort_by_created_at
    else
      nil
    end
  end


  private

  def sort_by_alpha
    @tags.sort { |a,b| a.name <=> b.name }
  end


  def sort_by_frequency
    @tags.sort { |a,b| b.count <=> a.count }
  end

  def sort_by_created_at
    @tags.sort { |a,b| @klass.first_use_of_tag_in_context(a.name, @context) <=> @klass.first_use_of_tag_in_context(b.name, @context) }
  end
end
