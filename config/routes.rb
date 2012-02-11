Tagteam::Application.routes.draw do

  resources :input_sources do
    collection do
      get :find
    end
  end
  resources :input_source

  resources :feed_retrievals

  resources :feed_items do
    member do
      get 'content'
    end
    collection do
      get 'by_date'
    end
  end

	resources :feeds do
		collection do
			post 'check_feed'
		end
	end

  resources :tags

  resources :hub_feeds do
    member do
      get 'reschedule_immediately'
      get 'retrievals'
      get 'more_details'
    end
    resources :feed_items do
      member do
        get 'content'
      end
      collection do
        get 'by_date'
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

    member do
      get 'search'
      post 'add_feed'
      get 'feeds'
      get 'custom_republished_feeds'
      get 'republishing'
      get 'tag_controls'
    end

    resources :hub_feeds do
      member do
        get 'reschedule_immediately'
        get 'retrievals'
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
      end
    end

    resources :tags

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
