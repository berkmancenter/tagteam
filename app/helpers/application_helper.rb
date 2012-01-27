module ApplicationHelper

  def tag_display(hub,tag)
    link_to(tag.name, hub_tag_path(hub,tag), :class => 'tag', :data_tag_id => tag.id, :data_hub_id => hub.id) 
  end

end
