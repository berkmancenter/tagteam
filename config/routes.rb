# frozen_string_literal: true
Rails.application.routes.draw do
  # TODO: enforce SSL for UsersController in production
  resources :users do
    member do
      post 'resend_confirmation_token'
      post 'resend_unlock_token'
      get 'roles_on'
    end
  end

  namespace :users do
    get 'search/autocomplete'
  end

  post 'bookmarklets/add_item'
  post 'bookmarklets/remove_item'
  get 'bookmarklets/add'
  get 'bookmarklets/confirm'

  post 'scheduled_tasks/expire_cache'
  post 'scheduled_tasks/update_feeds'

  resources :documentations

  resources :input_sources do
    collection do
      get :find
    end
  end
  resources :input_source

  resources :hub_feeds do
    collection do
      get 'autocomplete'
    end
    member do
      get 'reschedule_immediately'
      get 'more_details'
      get 'import'
      post 'import' => 'hub_feeds#import_items'
      get 'controls'
    end

    resources :feed_retrievals

    resources :feed_items do
      member do
        get 'content'
        get 'about'
        get 'related'
        get 'controls'
      end
    end
    resources :tags
    resources :tag_filters
  end

  get 'remix/:url_key' => 'republished_feeds#show', :as => 'remix'
  get 'remix/:url_key/items' => 'republished_feeds#items', :as => 'remix_items'

  get 'export_import' => 'export_import#index'
  get 'export_import/download' => 'export_import#download'
  post 'export_import' => 'export_import#import'

  resources :hubs do
    get 'tag/rss/:name' => 'tags#rss', :as => 'tag_rss', :constraints => { name: /.+/ }
    get 'tag/atom/:name' => 'tags#atom', :as => 'tag_atom', :constraints => { name: /.+/ }
    get 'tag/json/:name' => 'tags#json', :as => 'tag_json', :constraints => { name: /.+/ }
    get 'tag/xml/:name' => 'tags#xml', :as => 'tag_xml', :constraints => { name: /.+/ }
    get 'tag/:name' => 'tags#show', :as => 'tag_show', :constraints => { name: /.+/ }

    get 'user/:username' => 'users#tags', :as => 'user_tags', :constraints => { username: /[^\/]+/ }
    get 'user/:username/rss' => 'users#tags_rss', :as => 'user_tags_rss', :constraints => { username: /[^\/]+/ }
    get 'user/:username/atom' => 'users#tags_atom', :as => 'user_tags_atom', :constraints => { username: /[^\/]+/ }
    get 'user/:username/json' => 'users#tags_json', :as => 'user_tags_json', :constraints => { username: /[^\/]+/ }
    get 'user/:username/xml' => 'users#tags_xml', :as => 'user_tags_xml', :constraints => { username: /[^\/]+/ }

    get 'user/:username/tag/:tagname' => 'users#tags', :as => 'user_tags_name', :constraints => { tagname: /[^\/]+/, username: /.+/ }
    get 'user/:username/tag/:tagname/rss' => 'users#tags_rss', :as => 'user_tags_name_rss', :constraints => { tagname: /[^\/]+/, username: /.+/ }
    get 'user/:username/tag/:tagname/atom' => 'users#tags_atom', :as => 'user_tags_name_atom', :constraints => { tagname: /[^\/]+/, username: /.+/ }
    get 'user/:username/tag/:tagname/json' => 'users#tags_json', :as => 'user_tags_name_json', :constraints => { tagname: /[^\/]+/, username: /.+/ }
    get 'user/:username/tag/:tagname/xml' => 'users#tags_xml', :as => 'user_tags_name_xml', :constraints => { tagname: /[^\/]+/, username: /.+/ }

    member do
      get 'about'
      post 'recalc_all_tags'
      get 'item_search'
      post 'add_feed'
      get 'custom_republished_feeds'
      get 'tag_controls'
      get 'items'
      get 'by_date/:year/:month/:day' => 'hubs#by_date', :as => 'by_date'
      get 'retrievals'
      get 'my_bookmark_collections'
      get 'bookmark_collections'
      get 'community'
      get 'notifications'
      get 'settings'
      post 'add_roles'
      post 'remove_roles'
      post 'request_rights'
      get 'contact'
      get 'created'
      post 'set_notifications'
      post 'set_user_notifications'
      post 'set_settings'
    end

    collection do
      get 'list'
      get 'meta'
      get 'my'
      get 'background_activity'
      get 'all_items'
      get 'search'
    end

    resources :hub_feeds do
      collection do
        get 'autocomplete'
      end
      member do
        get 'reschedule_immediately'
        get 'more_details'
        get 'controls'
      end
    end

    resources :republished_feeds do
      member do
        get 'items'
        get 'inputs'
        get 'removals'
        get 'more_details'
      end
    end

    resources :tags do
      collection do
        get 'autocomplete'
      end
    end

    resources :tag_filters

    resources :feed_items do
      resources :tag_filters

      member do
        get 'tag_list'
        get 'content'
        get 'related'
      end
      #      collection do
      #        get 'by_date/:year/:month/:day' => 'feed_items#by_date', :as => 'by_date'
      #      end
    end
  end

  devise_for :users, path: 'accounts', controllers: {
    registrations: 'users/registrations'
  }

  require 'sidekiq/web'
  authenticate :user, ->(u) { u.has_role? :superadmin } do
    mount Sidekiq::Web => '/sidekiq'
  end

  namespace :admin do
    resources :user_approvals, only: [:index] do
      get :approve
      get :deny
    end
  end

  root 'hubs#home'
end
