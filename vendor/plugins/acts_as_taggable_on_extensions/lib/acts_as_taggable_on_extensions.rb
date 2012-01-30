ActsAsTaggableOn::Tag.class_eval do
  def contexts
    contexts = ActsAsTaggableOn::Tagging.select('context').where('tag_id = ? and context != ?',self.id,'tags').group('context')
    (contexts.length == 0) ? [] : contexts.collect{|tg| tg.context} 
  end
end

ActsAsTaggableOn::Tag.instance_eval do
  searchable do
    text :name
    string :contexts, :multiple => true
    string :name
  end
end
