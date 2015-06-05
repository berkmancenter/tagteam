module DelegatableRoles
  DELEGATABLE_ROLES_HASH = {
    editor: {
      name: 'Editor',
      description: 'Has edited metadata about this hub - does not confer any special privileges.',
      objects_of_concern: lambda{ |user,hub| return [] }
    },
    owner: {
      name: 'Owner',
      description: 'Owns this hub, effectively able to do everything',
      objects_of_concern: lambda{ |user,hub| return [] }
    },
    creator: {
      name: 'Creator',
      description: 'Created this hub - does not confer any special privileges',
      objects_of_concern: lambda{ |user,hub| return [] }
    },
    bookmarker: {
      name: 'Tagger',
      description: 'Can add bookmarks to this hub via the bookmarklet',
      objects_of_concern: lambda{ |user,hub|
        # Find all bookmark collections (and their hub feeds) in this
        # hub owned by this user.
        bookmarking_feeds = user.my_bookmarking_bookmark_collections_in(hub.id)
        return [
          bookmarking_feeds,
          bookmarking_feeds.collect{ |f|
            f.hub_feeds.reject{|hf| ! user.is?(:owner, hf)}
          }
        ].flatten.compact
      }
    },
    remixer: {
      name: 'Feed remixer',
      description: 'Can remix items in this hub into new remix feeds',
      objects_of_concern: lambda{ |user,hub|
        #Find all republished_feeds in this hub owned by this user.
        return user.my_objects_in(RepublishedFeed, hub)
      }
    },
    hub_tag_filterer: {
      name: 'Hub-wide tag filter manager',
      description: 'Can manage hub-wide tag filters in this hub',
      objects_of_concern: lambda{ |user,hub|
        #Find all hub_tag_filters in this hub owned by this user.
        return user.my_objects_in(TagFilter, hub).
          select{ |filter| filter.scope_type == 'Hub' }
      }
    },
    hub_feed_tag_filterer: {
      name: 'Feed-wide tag filter manager',
      description: 'Can manage feed-level tag filters in this hub',
      objects_of_concern: lambda{ |user,hub|
        return user.my_objects_in(TagFilter, hub).
          select{ |filter| filter.scope_type == 'HubFeed' }
      }
    },
    hub_feed_item_tag_filterer: {
      name: 'Feed item tag filter manager',
      description: 'Can manage item-level tag filters in this hub',
      objects_of_concern: lambda{ |user,hub|
        #Find all hub_feed_item_tag_filters in this hub owned by this user.
        return user.my_objects_in(TagFilter, hub).
          select{ |filter| filter.scope_type == 'FeedItem' }
      }
    },
    inputter: {
      name: 'Input feed manager',
      description: 'Can manage input feeds',
      objects_of_concern: lambda{ |user,hub|
        #Find all hub_feeds that aren't bookmarking collections in this
        # hub owned by this user.
        hub_feeds_of_concern = user.my_objects_in(HubFeed, hub)
        return hub_feeds_of_concern.reject{|hf| hf.feed.is_bookmarking_feed? == true}
      }
    }
  }

  DELEGATABLE_ROLES_FOR_FORMS = DELEGATABLE_ROLES_HASH.keys.
    reject{|r| [:creator,:editor].include?(r) }.
    collect{|r| [r, DELEGATABLE_ROLES_HASH[r][:name]]}

  DELEGATABLE_ROLES = DELEGATABLE_ROLES_HASH.keys.reject{|r| r == :creator}
end
