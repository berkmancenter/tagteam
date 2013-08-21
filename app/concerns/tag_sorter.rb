class TagSorter
  SORT_OPTS = %w(alpha frequency created_at)
  def initialize(args)
    @tags = args[:tags]
    raise "No tags supplied" if @tags.blank?

    @sort_by = args[:sort_by].to_s
    raise "No sort option supplied" if @sort_by.blank?
    raise "Invalid sort option: please use #{SORT_OPTS.join(" or ")}" unless SORT_OPTS.include?(@sort_by)
  end

  def sort
    case @sort_by
    when "alpha"
      sort_by_alpha
    when "frequency"
      sort_by_frequency
    when "created_at"
      sort_by_created_at
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
    @tags.sort { |a,b| b.created_at <=> a.created_at }
  end
end
