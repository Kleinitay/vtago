Dreamline::Application.routes.draw do |map|
  resources :users
  resources :videos
#  resources :comments
  
  root :to => "application#home"
  match "/beta" => "application#beta"
# ___________________ Videos ______________________________________________________

  get 'video/pending_count' => 'videos#analyze_count', :as => 'analyze_count'

  match "/video/search_results" => "videos#search"
  # Moozly: to remove - why doesn't work with *page without a page
  match 'video/most_popular'        => 'videos#list', :as => :most_popular_videos,  :order=> "most popular", :page => "0"
  match 'video/latest'              => 'videos#list', :as => :latest_videos,        :order=> "latest", :page => "0"
  match 'users/:id/videos'          => 'videos#list', :as => :user_videos,          :page => "0", :order=> "by_user"
  #------------------------------------------------------------------------------------------------------------------------
  match 'video/latest/*page'        => 'videos#list', :as => :latest_videos,        :order=> "latest"#, :requirements => { :page => /(['0'-'9']*)?/}
  match 'video/most_popular/*page'  => 'videos#list', :as => :most_popular_videos,  :order=> "most popular" #, :requirements => { :page => /([0-9]*)?/}
  match 'users/:id/videos/*page'    => 'videos#list', :as => :user_videos,          :order=> "by_user"

  Video::CATEGORIES.values.each do |order|
    # Moozly: to remove - why doesn't work with *page without a page
    match "video/#{order}"          => 'videos#list', :as => :category, :order => "#{order}", :page => "0"
    match "video/#{order}/*page"    => 'videos#list', :as => :category, :order => "#{order}" #, :requirements => { :page => /([0-9]*)?/}
  end

  match 'video/:fb_id'                       => 'videos#show',                  :as => :video,            :requirements => { :fb_id => /([0-9]*)?/ }
  match 'video/:id/edit'                     => 'videos#edit',                  :as => :edit_video,       :requirements => { :fb_id => /([0-9]*)?/ }
  match 'video/:id/edit/new'                 => 'videos#edit',                  :as => :edit_video_new,   :requirements => { :fb_id => /([0-9]*)?/ }
  match 'video/:id/edit_tags(/new)'          => 'videos#edit_tags',             :as => :edit_video_tags,  :requirements => { :fb_id => /([0-9]*)?/ }
  match 'video/:id/update_tags(/new)'        => "videos#update_tags",           :as => :update_video_tags
  match 'video/:id/update_video(/new)'       => "videos#update_video",          :as => :update_video
  match 'video/:fb_id/analyze'               => 'videos#analyze',               :as => :analyze_video,    :requirements => { :fb_id => /([0-9]*)?/ }
  get   'video/:fb_id/views'                 => 'videos#get_views_count',       :as => :get_views_count,  :requirements => { :fb_id => /([0-9]*)?/ }
  post  'video/:fb_id/views'                 => 'videos#increment_views_count', :as => :inc_views_count,  :requirements => { :fb_id => /([0-9]*)?/ }

# ___________________ FB Videos ______________________________________________________
  match 'fb/video/:fb_id'                       => 'videos#show',            :as => :fb_video,            :canvas => "true", :requirements => { :fb_id => /([0-9]*)?/ }
  match 'fb/list'                               => 'videos#list',            :as => :fb_video_list,       :canvas => "true", :order=> "by_user"
  match 'fb/users/:id/videos'                   => 'users#videos',           :as => :fb_user_videos,      :canvas => "true"
  match 'fb/new'                                => 'videos#new',             :as => :fb_video_upload,     :canvas => "true"
  match 'fb/create'                             => 'videos#create',          :as => :fb_video_create,     :canvas => "true"
  match 'fb/vtaggees'                           => 'videos#vtaggees',        :as => :fb_vtaggees,         :canvas => "true"
  match 'fb/about'                              => 'videos#about',           :as => :fb_about,            :canvas => "true"
  match 'fb/video/:id/edit'                     => 'videos#edit',            :as => :fb_edit_video,       :canvas => "true", :requirements => { :fb_id => /([0-9]*)?/ }
  match 'fb/video/:id/edit/new'                 => 'videos#edit',            :as => :fb_edit_video_new,   :canvas => "true", :requirements => { :fb_id => /([0-9]*)?/ }
  match 'fb/video/:id/edit_tags(/new)'          => 'videos#edit_tags',       :as => :fb_edit_video_tags,  :canvas => "true", :requirements => { :fb_id => /([0-9]*)?/ }
  match 'fb/video/:id/update_tags(/new)'        => 'videos#update_tags',     :as => :fb_update_video_tags,:canvas => "true", :requirements => { :fb_id => /([0-9]*)?/ }
  match 'fb/video/:id/update_video(/new)'       => 'videos#update_video',    :as => :fb_update_video,     :canvas => "true", :requirements => { :fb_id => /([0-9]*)?/ }
  match 'fb/video/:fb_id/analyze'               => 'videos#analyze',         :as => :fb_analyze_video,    :canvas => "true", :requirements => { :fb_id => /([0-9]*)?/ }
#------------------------------------------------------------------------------------------------------------------------

# ___________________ Users ______________________________________________________

  match 'users/:id/videos/*page'  => 'users#videos', :as => :user_videos

#    match 'sign_up'             => 'users#new', :as => 'sign_up'
     match 'sign_in'             => 'sessions#new', :as => 'sign_in'
     match 'email_subscribe'     => 'sessions#email_subscribe', :as => 'email_subscribe' #for landing page invites
     match 'sign_out'            => 'sessions#destroy', :as => 'destroy'
#    match 'auth'                => 'sessions#aoth_athenticate', :as => 'aoth'
#    match 'auth_return'         => 'sessions#aoth_athenticate_return', :as => 'aoth_return'
    #__________________omniauth paths_______________________________________________
    match 'auth/:provider/callback' => 'authentication#create'
    match 'canvas' => 'authentication#canvas'
    match 'auth/destroy' => 'authentication#destroy'
    match 'auth/failure' => 'sessions#new'

#------------- Text -------------------------------------------------------------
  match 'about/beta' => 'application#about', :as =>'about_beta', :beta => "true"
  match 'about'      => 'application#about', :as =>'about'

  match 'toc/beta' => 'application#toc', :as =>'toc_beta', :beta => "true"
  match 'toc'      => 'application#toc', :as =>'toc'

#------------- Notifications -------------------------------------------------------------

  get 'notifications/all' => 'notifications#all', :as =>'notifications'
  get 'notifications/count' => 'notifications#unviewed_count', :as =>'notifications_count'
  match 'notifications/mark' => 'notifications#mark_viewed', :as =>'notifications_mark'

  
#____________________________________________________________________________________________
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
 #_____________________________________________________________________________________________________________ 


  
end