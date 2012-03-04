class VideosController < ApplicationController

 before_filter :redirect_first_page_to_base
 before_filter :authorize, :only => [:edit, :edit_tags]

	def show
		video_id = params[:id].to_i
		@video = Video.for_view(video_id) if video_id != 0
    @video.gen_player_file current_user
		if !@video then render_404 and return end
	  check_video_redirection(@video)
	  @user = @video.user
	  @own_videos = current_user == @user ? true : false
	  @comments, @total_comments_count = Comment.get_video_comments(video_id)

	  #sidebar
	  get_sidebar_data # latest
	  @user_videos = Video.get_videos_by_user(1, @user.id, true, 3)
	  @trending_videos = Video.get_videos_by_sort(1,"popular", true ,3)
	  @active_users = User.get_users_by_activity
	end
	
	def list
	  @videos = []
	  @order = params[:order]
	  current_page = (params[:page] == "0" ? "1" : params[:page]).to_i
	  case
      when @order == "most popular" || @order == "latest"
        @videos = Video.get_videos_by_sort(current_page, @order, false)
	    when key = Video::CATEGORIES.key(@order)
	      @videos = Video.get_videos_by_category(key)
	      @category = true
	    else
	      render_404 and return
    end
    @page_title = @order.titleize
    @empty_message = "There are no videos to present for this page."
    get_sidebar_data

  end

  def check_video_redirection(video)
    if request.path != video.uri
      redirect_to(request.request_uri.sub(request.path, video.uri), :status => 301)
    end  
  end

  def get_sidebar_data
    if @order == "latest"
      @sidebar_order = "most popular"
      @sidebar_list_title = "Trending Now"
    else
      @sidebar_order = "latest"
      @sidebar_list_title = "Latest Ones"
    end
    @sidebar_videos = Video.get_videos_by_sort(1,@sidebar_order, true ,3)
    @active_users = User.get_users_by_activity
  end

  def new
    @video = Video.new
  end

  def create
    unless !signed_in? || !params[:video]
      more_params = {:user_id => current_user.id, :duration => 0} #temp duration
      @video = Video.new(params[:video].merge(more_params))
      if @video.save
         @video.detect_and_convert(fb_graph)
         unless !@video.fbid.nil?
           @video.delay.upload_video_to_fb(fb_graph)
         end
        flash[:notice] = "Video has been uploaded"
        redirect_to "/video/#{@video.id}/edit_tags/new"
      else
        render 'new'
      end
    else
      redirect_to "/"
    end
  end

  def edit
    @video = Video.find(params[:id])
  end

  def edit_tags
    @new = params[:new]=="new" ? true : false
    @video = Video.find(params[:id])
    @page_title = "#{@video.title.titleize} - #{@new ? "Add Tags" : "Edit"} Tags"
    @user = current_user
    @taggees = @video.video_taggees
    friends = fb_graph.get_connections(current_user.fb_id,'friends')
    @friends = {}
    friends.map {|friend| @friends[friend["name"]] = friend["id"]}
    @friends[current_user.nick] = current_user.fb_id
    @names_arr = @friends.keys
    @gallery_var=0 #this variable is used to count the number of boxes in the gallery in order to put dynamic class on the last box
    #@likes = graph.get_connections("me", "likes")
    #sidebar
	  get_sidebar_data # latest
	  @user_videos = Video.get_videos_by_user(1, @user.id, true, 3)
	  @trending_videos = Video.get_videos_by_sort(1,"popular", true ,3)
	  @active_users = User.get_users_by_activity
  end

  def update_video
    unless !signed_in? || !params[:video]
      @video = Video.find(params[:id])
      if @video.update_attributes(params[:video])
        redirect_to video_path @video
      end# if update_attributes
    else
      redirect_to "/"
    end
  end

  def update_tags
    unless !signed_in?
      @video = Video.find(params[:id])
      #---------------------there are at least one taggee left
      unless !params[:video]
        @new = params[:new]=="new" ? true : false
        existing_taggees = @video.video_taggees_uniq.map(&:fb_id)
        updated_taggees_ids = []
        updated_taggees_ids = params[:video][:existing_taggee_attributes].values.map!{|h| h["fb_id"].to_i}.uniq.reject{ |id| id==0 }
        if @video.update_attributes(params[:video])
          if updated_taggees_ids.any?
            if @new
              new_taggees = updated_taggees_ids
            else
              new_taggees = (updated_taggees_ids - existing_taggees)
            end
            post_vtag(@new, new_taggees, @video.id, @video.title.titleize)
          end #if ids
        end# if update_attributes
        #---------------------all taggees are removed
      else
        @video.delete_taggees
      end
      redirect_to video_path (@video)
    else
      redirect_to "/"
    end
  end

  def destroy
    video = Video.find(params[:id])
    fb_delete = false #currently seems unavailable option by FB!
    fb_delete ? graph = fb_graph : nil
    flash[:notice] = video.delete(fb_delete, graph)
    redirect_to "/users/#{current_user.id}/videos"
  end
end
