Milkman::Application.routes.draw do
  get "explore/index"

  root :to => "welcome#index"

  get "subjects/index"

  match 'groups' => 'groups#index'
  match 'groups/:zoo_id/export' => 'groups#export'
  match 'groups/:zoo_id(/:page)' => 'groups#show', defaults: { page: 1 }
  match 'subjects/:zoo_id' => 'subjects#show'
  match 'page/:page_id' => 'subjects#page'
  match 'coordinates' => 'subjects#coordinates'
  match 'subjects/preview/:zoo_id' => 'subjects#preview'
  match 'subjects/simbad/:zoo_id' => 'subjects#simbad'
  match 'subjects/raw/:zoo_id' => 'subjects#raw'
  match 'status(/:status)(/:page)' => 'subjects#index', defaults: {status: 'active', page: 1}

  match 'catalogues/dr2/bubbles' => 'catalogue_objects#bubbles'

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
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
