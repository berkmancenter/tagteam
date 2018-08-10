# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # TODO: enforce SSL for UsersController in production
  resources :users, except: :index do
    member do
      post 'resend_confirmation_token'
      post 'resend_unlock_token'
      get 'roles_on'
      post 'lock_user'
      post 'superadmin_role'
      post 'documentation_admin_role'
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

  resources :hub_feeds, except: :new do
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
        delete 'remove_item'
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
    get 'tag/:name/statistics' => 'tags#statistics', :as => 'tag_statistics', :constraints => { name: /.+/ }
    get 'tag/:name' => 'tags#show', :as => 'tag_show', :constraints => { name: /.+/ }, :defaults => { :format => 'html' }

    get 'user/:username' => 'users#hub_items', :as => 'user_hub_items', :constraints => { username: /[^\/]+/ }
    get 'user/:username/tags' => 'tags#index', :as => 'user_hub_items_tags', :constraints => { username: /[^\/]+/ }
    get 'user/:username/filters' => 'tag_filters#index', :as => 'user_hub_items_filters', :constraints => { username: /[^\/]+/ }
    get 'user/:username/updates' => 'feed_retrievals#index', :as => 'user_hub_items_updates', :constraints => { username: /[^\/]+/ }
    get 'user/:username/about' => 'hub_feeds#show', :as => 'user_hub_items_about', :constraints => { username: /[^\/]+/ }

    get 'user/:username/rss' => 'users#tags_rss', :as => 'user_tags_rss', :constraints => { username: /[^\/]+/ }
    get 'user/:username/atom' => 'users#tags_atom', :as => 'user_tags_atom', :constraints => { username: /[^\/]+/ }
    get 'user/:username/json' => 'users#tags_json', :as => 'user_tags_json', :constraints => { username: /[^\/]+/ }
    get 'user/:username/xml' => 'users#tags_xml', :as => 'user_tags_xml', :constraints => { username: /[^\/]+/ }
    get 'user/:username/tag/:tagname(/:deprecated)' => 'users#tags', :as => 'user_tags_name', :constraints => { tagname: /[^\/]+/, username: /.+/ }, defaults: { deprecated: nil }
    get 'user/:username/tag/:tagname(/:deprecated)/rss' => 'users#tags_rss', :as => 'user_tags_name_rss', :constraints => { tagname: /[^\/]+/, username: /.+/ }, defaults: { deprecated: nil }
    get 'user/:username/tag/:tagname(/:deprecated)/atom' => 'users#tags_atom', :as => 'user_tags_name_atom', :constraints => { tagname: /[^\/]+/, username: /.+/ }, defaults: { deprecated: nil }
    get 'user/:username/tag/:tagname(/:deprecated)/json' => 'users#tags_json', :as => 'user_tags_name_json', :constraints => { tagname: /[^\/]+/, username: /.+/ }, defaults: { deprecated: nil }
    get 'user/:username/tag/:tagname(/:deprecated)/xml' => 'users#tags_xml', :as => 'user_tags_name_xml', :constraints => { tagname: /[^\/]+/, username: /.+/ }, defaults: { deprecated: nil }

    get 'tags_used_not_approved' => 'tags#tags_used_not_approved'
    get 'deprecated_tags' => 'tags#deprecated_tags'
    get 'tags_approved' => 'tags#tags_approved'

    member do
      get 'about'
      post 'recalc_all_tags'
      get 'item_search'
      post 'add_feed'
      put 'unsubscribe_feed/:feed_id' => 'hubs#unsubscribe_feed', as: 'unsubscribe_feed'
      get 'custom_republished_feeds'
      get 'tag_controls'
      get 'items'
      get 'by_date/:year/:month/:day' => 'hubs#by_date', :as => 'by_date'
      get 'retrievals'
      get 'my_bookmark_collections'
      get 'taggers'
      get 'team'
      get 'statistics'
      get 'notifications'
      get 'settings'
      get 'scoreboard'
      post 'add_roles'
      post 'remove_roles'
      post 'request_rights'
      get 'contact'
      get 'created'
      post 'set_notifications'
      post 'set_user_notifications'
      post 'set_settings'
      get 'active_taggers'
      post 'approve_tag'
      post 'unapprove_tag'
      post 'deprecate_tag'
      post 'undeprecate_tag'
      delete 'remove_delimiter'
    end

    collection do
      get 'list'
      get 'meta'
      get 'my'
      get 'background_activity'
      get 'all_items'
      get 'search'
      delete 'destroy_hubs', as: 'destroy_hubs'
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

    resources :messages, only: %i[new create]
  end

  devise_for :users, path: 'accounts', controllers: {
    registrations: 'users/registrations'
  }

  # Allow users to log out using both DELETE and GET
  devise_scope :user do
    get '/accounts/sign_out', to: 'devise/sessions#destroy'
  end

  require 'sidekiq/web'
  authenticate :user, ->(u) { u.has_role? :superadmin } do
    mount Sidekiq::Web => '/sidekiq'
  end

  namespace :admin do
    root 'home#index'

    resources :user_approvals, only: [:index] do
      get :approve
      get :deny
    end

    resources :users, only: :index
    resources :hubs, only: %i[index destroy]
    resources :settings, only: %i[new create update]
  end
  root 'hubs#home'
end
