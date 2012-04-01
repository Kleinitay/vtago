class VideosController < ApplicationController

  before_filter :check_canvas
  layout :resolve_layout
  before_filter :redirect_first_page_to_base, :only => [:list], :if => proc{@canvas}
  before_filter :authorize, :only => [:edit, :edit_tags]

	def show
	  fb_id = params[:fb_id].to_i
	  @video = Video.for_view(fb_id)
		if !@video then render_404 and return end
	  check_video_redirection(@video) unless @canvas
	  @user = @video.user
	  @own_videos = current_user == @user ? true : false
	  @video.gen_player_file current_user if @video.analyzed
    unless @canvas
      #sidebar
      get_sidebar_data # latest
      @user_videos = Video.get_videos_by_user(1, @user.id, true, false, 3)
      @trending_videos = Video.get_videos_by_sort(1,"popular", true , false, 3)
      @active_users = User.get_users_by_activity
    end
    #Moozly: still 2 views
    render 'fb_videos/show', :layout => 'fb_videos' if @canvas
	end
	
	def list
	  @order = params[:order]
	  current_page = (params[:page] == "0" ? "1" : params[:page]).to_i
	  case
      when @order == "most popular" || @order == "latest"
        @videos = Video.get_videos_by_sort(current_page, @order, false, @canvas)
        @page_title = @order.titleize
        @empty_message = "There are no videos to present for this page."
	    when key = Video::CATEGORIES.key(@order)
	      @videos = Video.get_videos_by_category(key)
	      @category = true
	      @page_title = @order.titleize
        @empty_message = "There are no videos to present for this page."
	    when @order == "by_user"
	      @user = @canvas ? current_user : User.find(params[:id])
	      @videos = Video.get_videos_by_user(current_page, @user.id, false, @canvas)
	      @user_videos_page = true
        @own_videos = current_user == @user ? true : false
        @page_title = @own_videos ? "My" : "#{@user.nick}'s"
        @empty_message = "This user does not have any videos yet."
	    else
	      render_404 and return
    end
    get_sidebar_data unless @canvas

    #Moozly: still 2 views
    render 'fb_videos/list' if @canvas
  end

  def vtaggees
    @page_title = "I got Vtagged"
    user = current_user
    @videos = Video.find_all_by_vtagged_user(user.fb_id)
    @empty_message = "You haven't been Vtagged Yet :-(."
    render 'fb_videos/vtaggees' if @canvas
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
    @sidebar_videos = Video.get_videos_by_sort(1,@sidebar_order, true , false, 3)
    @active_users = User.get_users_by_activity
  end

  def new
    @video = Video.new
    #Moozly: still 2 views
    render 'fb_videos/new' if @canvas
  end

  def create
    unless !signed_in? || !params[:video]
      more_params = {:user_id => current_user.id, :duration => 0} #temp duration
      @video = Video.new(params[:video].merge(more_params))
      if @video.save
         @video.detect_and_convert
         unless !@video.fb_id.nil?
           @video.upload_video_to_fb
         end
        flash[:notice] = "Video has been uploaded"
        redirect_to "#{'/fb' if @canvas}/video/#{@video.fb_id}/edit_tags/new"
      else
        render "#{'/fb/' if @canvas}new"
      end
    else
      redirect_to "/#{'fb/list' if @canvas}"
    end
  end

  def edit
    @video = Video.find_by_fb_id(params[:fb_id])
    @page_title = "Edit Video Details"

    #Moozly: still 2 views
    render 'fb_videos/edit' if @canvas
  end

  def analyze
    fb_id = params[:fb_id]
	  @video = Video.for_view(fb_id)
    #Moozly: temp!!! Itay - see whats need to be done
	  @video.update_attribute(:state,"pending")
    @video.detect_and_convert
    redirect_to "#{'/fb' if @canvas}/video/#{@video.fb_id}/edit_tags/new"
  end

  def edit_tags
    @new = params[:new]=="new" ? true : false
    @video = Video.find_by_fb_id(params[:fb_id])
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
    unless @canvas
      #sidebar
	    get_sidebar_data # latest
	    @user_videos = Video.get_videos_by_user(1, @user.id, true, false, 3)
	    @trending_videos = Video.get_videos_by_sort(1,"popular", true , false, 3)
	    @active_users = User.get_users_by_activity
	  end
	  #Moozly: still 2 views
    render 'fb_videos/edit_tags' if @canvas
  end

  def update_video
    unless !signed_in? || !params[:video]
      @video = Video.find_by_fb_id(params[:fb_id])
      if @video.update_attributes(params[:video])
        fb_graph.put_object(@video.fb_id, "", :name => @video.title, :description => @video.description)
        redirect_to @canvas ? @video.fb_uri : (video_path @video)
      end# if update_attributes
    else
      redirect_to "/#{'fb/list' if @canvas}"
    end
  end

  def update_tags
    unless !signed_in?
      @video = Video.find_by_fb_id(params[:fb_id])
      logger.info "the video to update: " + @video.to_s
      #---------------------there are at least one taggee left
      unless !params[:video]
        @new = request.path.index("/new") ? true : false
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

      redirect_to @canvas ? @video.fb_uri : (@video.uri)

    else
      redirect_to "/#{'fb/list' if @canvas}"
    end
  end

  def destroy #not_using from app
    video = Video.find_by_fb_id(params[:fb_id])
    #fb_delete = false #currently seems unavailable option by FB!
    #fb_delete ? graph = fb_graph : nil
    flash[:notice] = video.delete(fb_delete, graph)
    redirect_to "/users/#{current_user.id}/videos"
  end

  def about
    # Still 2 views...
    render 'fb_videos/about' if @canvas
  end

  private

  def check_canvas
    @canvas = params["canvas"] == "true"
  end

  def resolve_layout
    @canvas ? "fb_videos" : "application"
  end

end
