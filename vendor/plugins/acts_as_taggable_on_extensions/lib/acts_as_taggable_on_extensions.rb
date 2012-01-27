ActsAsTaggableOn::Tag.class_eval{
  def contexts
    contexts = ActsAsTaggableOn::Tagging.select('context').where('tag_id = ? and context != ?',self.id,'tags').group('context')
    (contexts.length == 0) ? [] : contexts.collect{|tg| tg.context} 
  end
}

ActsAsTaggableOn::Tag.instance_eval{
  searchable do
    text :name
    string :contexts, :multiple => true
    string :name
  end
}
