module AuthUtilities

  def owners
    owner_list = self.accepted_roles.reject{|r| r.name != 'owner'}
    (owner_list.blank?) ? nil : owner_list.first.users.compact.uniq
  end

  def creators
    creator_list = self.accepted_roles.reject{|r| r.name != 'creator'}
    (creator_list.blank?) ? nil : creator_list.first.users.compact.uniq
  end

  def editors
    editor_list = self.accepted_roles.reject{|r| r.name != 'editor'}
    (editor_list.blank?) ? nil : editor_list.first.users.compact.uniq
  end

end
