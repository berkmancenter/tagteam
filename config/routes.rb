Tagteam::Application.routes.draw do

  resources :documentations

  resources :input_sources do
    collection do
      get :find
    end
  end
  resources :input_source

  resources :hub_feeds do
    member do
      get 'reschedule_immediately'
      get 'more_details'
    end

    resources :feed_retrievals

    resources :feed_items do
      member do
        get 'content'
      end
    end
    resources :tags
    resources :hub_feed_tag_filters do
      member do
        post 'move_higher'
        post 'move_lower'
      end
    end
  end

  resources :hubs do

    match 'tag/:name' => 'tags#show', :as => 'tag_show'
    match 'tag/:name/rss' => 'tags#rss', :as => 'tag_rss'
    match 'tag/:name/atom' => 'tags#atom', :as => 'tag_atom'

    member do
      post 'recalc_all_tags'
      get 'search'
      post 'add_feed'
      get 'custom_republished_feeds'
      get 'tag_controls'
      get 'items'
      get 'by_date'
      get 'retrievals'
    end

    resources :hub_feeds do
      member do
        get 'reschedule_immediately'
        get 'more_details'
      end
    end

    resources :republished_feeds do
      member do
        get 'rss'
        get 'atom'
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

    resources :hub_tag_filters do
      member do
        post 'move_higher'
        post 'move_lower'
      end
    end

    resources :feed_items do
      resources :hub_feed_item_tag_filters do
        member do
          post 'move_higher'
          post 'move_lower'
        end
      end
      member do
        get 'content'
      end
      collection do
        get 'by_date'
      end
    end

  end

  devise_for :users

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
