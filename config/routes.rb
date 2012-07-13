Tagteam::Application.routes.draw do

  resources :users, :constraints => { :protocol => ((Rails.env == 'production' && Tagteam::Application.config.ssl_for_user_accounts) ? {:protocol => 'https'} : {}) } do
    collection do
      get 'autocomplete'
    end
    member do
      post 'resend_confirmation_token'
      post 'resend_unlock_token'
      get 'roles_on'
    end
  end

  post "bookmarklets/add_item"
  post "bookmarklets/remove_item"
  get "bookmarklets/add"
  get "bookmarklets/confirm"

  post "scheduled_tasks/expire_cache"
  post "scheduled_tasks/update_feeds"

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
      post 'import'
      get 'controls'
    end

    resources :feed_retrievals

    resources :feed_items do
      member do
        get 'content'
        get 'related'
        get 'controls'
      end
    end
    resources :tags
    resources :hub_feed_tag_filters
  end

  match 'remix/:url_key' => 'republished_feeds#show', :as => 'remix'
  match 'remix/:url_key/items' => 'republished_feeds#items', :as => 'remix_items'

  resources :hubs do

    match 'tag/rss/:name' => 'tags#rss', :as => 'tag_rss', :constraints => { :name => /.+/ }
    match 'tag/atom/:name' => 'tags#atom', :as => 'tag_atom', :constraints => { :name => /.+/ }
    match 'tag/json/:name' => 'tags#json', :as => 'tag_json', :constraints => { :name => /.+/ }
    match 'tag/xml/:name' => 'tags#xml', :as => 'tag_xml', :constraints => { :name => /.+/ }
    match 'tag/:name' => 'tags#show', :as => 'tag_show', :constraints => { :name => /.+/ }

    member do
      post 'recalc_all_tags'
      get 'search'
      get 'item_search'
      post 'add_feed'
      get 'custom_republished_feeds'
      get 'tag_controls'
      get 'items'
      match 'by_date/:year/:month/:day' => 'hubs#by_date', :as => 'by_date'
      get 'retrievals'
      get 'my_bookmark_collections'
      get 'bookmark_collections'
      get 'community'
      post 'add_roles'
      post 'remove_roles'
      post 'request_rights'
      get 'contact'
    end

    collection do
      get 'meta'
      get 'my'
      get 'background_activity'
      get 'all_items'
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

    resources :hub_tag_filters

    resources :feed_items do

      resources :hub_feed_item_tag_filters

      member do
        get 'content'
        get 'related'
      end
#      collection do
#        match 'by_date/:year/:month/:day' => 'feed_items#by_date', :as => 'by_date'
#      end
    end

  end

  #devise_for :users, :path => 'accounts'
  devise_for :users, :path => 'accounts', :constraints => { :protocol => ((Rails.env == 'production' && Tagteam::Application.config.ssl_for_user_accounts) ? {:protocol => 'https'} : {}) }

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.

  root :to => "hubs#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
