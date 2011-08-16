atom_feed :language => 'en-US' do |atom|
  atom.title @republished_feed.title
  atom.updated @republished_feed.updated_at

  @republished_feed.items.each do |item|
    atom.entry( item ) do |entry|
      entry.url item.url 
      entry.title item.title
      entry.content item.content, :type => 'html'
      entry.updated(item.date_published.strftime("%Y-%m-%dT%H:%M:%SZ")) 
      entry.author do |author|
        author.name item.author
      end
    end
  end
end

