module ApplicationHelper

  def tag_display(hub,tag, options = {})
    options.merge!({:class => 'tag', :data_tag_id => tag.id, :data_hub_id => hub.id})
    link_to(tag.name, hub_tag_path(hub,tag), options) 
  end

end
