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
      @user_videos = Video.get_videos_by_user(1, @user.id, false, 3)
      @trending_videos = Video.get_videos_by_sort(1,"popular", false, 3)
      @active_users = User.get_users_by_activity
    end
    #Moozly: still 2 views
    render 'fb_videos/show', :layout => 'fb_videos' if @canvas
  end

  def list
    @order = params[:order]
    current_page = [params[:page].to_i, 1].max
    case
      when @order == "most popular" || @order == "latest"
        @videos = Video.get_videos_by_sort(current_page, @order, @canvas)
        @page_title = @order.titleize
        @empty_message = "There are no videos to present for this page."
      when key = Video::CATEGORIES.key(@order)
        @videos = Video.get_videos_by_category(key)
        @category = true
        @page_title = @order.titleize
        @empty_message = "There are no videos to present for this page."
      when @order == "by_user"
        @user = @canvas ? current_user : User.find(params[:id])
        @own_videos = current_user == @user ? true : false
        @videos = Video.get_videos_by_user(current_page, @user.id, @own_videos, @canvas)
        @user_videos_page = true
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
    @sidebar_videos = Video.get_videos_by_sort(1,@sidebar_order, false, 3)
    @active_users = User.get_users_by_activity
  end

  def new
    @video = Video.new
    #Moozly: still 2 views
    render 'fb_videos/new' if @canvas
  end

  #new video, upload to Facebook + analyze
  def create
    logger.info "in video.create"
    unless !signed_in? || !params[:video]
      logger.info "creating video with " + params.to_s
      more_params = {:user_id => current_user.id, :duration => 0} #temp duration
      @video = Video.new(params[:video].merge(more_params))
      @video.fb_uploaded = !@video.fb_id.nil?
      if @video.save
        @video.delay(:queue => 'detect').detect_and_convert(@canvas)
        @video.delay(:queue => 'upload').upload_video_to_fb(10, 3, @canvas, current_user)
        flash[:notice] = "Video has been uploaded"
        logger.info "New video created"
        redirect_to @canvas ? "/fb/video/#{@video.id}/edit" : edit_video_path(@video)
      else
        redirect_to "#{'/fb/' if @canvas}new"
      end
    else
      redirect_to "/#{'fb/list' if @canvas}"
    end
  end

  def edit
    @video = Video.find(params[:id]) # Edit expects ID not FB_ID 
    @page_title = "Edit Video Details"

    #Moozly: still 2 views
    render 'fb_videos/edit' if @canvas
  end

  #video is already on fb - vtago this video
  def analyze
    logger.info "-------------in the analyze---------------"
    fb_id = params[:fb_id]
    @video = Video.for_view(fb_id)
    @video.fb_uploaded = true
    @video.update_attribute(:state,"pending")
    @video.delay(:queue => 'detect').detect_and_convert(@canvas)
    redirect_to @canvas ? fb_edit_video_path(@video) : edit_video_path(@video)
  end

  def edit_tags

    logger.info "in the edit tags"
    @new = params[:new]=="new" ? true : false
    @video = Video.find(params[:id])
    @page_title = "#{@video.title.titleize} - #{@new ? "Add Tags" : "Edit"} Tags"
    @user = current_user
    @taggees = @video.video_taggees
    friends = current_user.fb_graph.get_connections(current_user.fb_id,'friends')
  	unless @video.state == "ready"
  	  if @video.fb_uploaded
        logger.info "---Video is uploaded and ready"
  	 	  @video.done!
  	 	else
        logger.info "---Video is just analyzed"
  	 	  @video.tagged!
  	 	end
    end
    @friends = friends.map { |friend| {'value' => friend['name'], 'id' => friend['id']} }
    @friends << {'value' => current_user.nick, 'id' => current_user.fb_id}
    logger.info "The parameters for the edit tags are: " + @new.to_s + @video.to_s + @page_title.to_s + @user.to_s + @taggees.to_s + @friends.to_s + @canvas.to_s
    unless @canvas
      #sidebar
      get_sidebar_data # latest
      @user_videos = Video.get_videos_by_user(1, @user.id, false, false, 3)
      @trending_videos = Video.get_videos_by_sort(1,"popular", false, 3)
      @active_users = User.get_users_by_activity
    end
                   #Moozly: still 2 views
    render 'fb_videos/edit_tags' if @canvas
  end

  def update_video
    redirect_to "/#{@canvas ? 'fb/list' : 'video/latest'}" and return unless signed_in? and params[:video]

    @video = Video.find(params[:id])
    if @video.update_attributes(params[:video])
      if @video.fb_id
        current_user.fb_graph.put_object(@video.fb_id, "", :name => @video.title, :description => @video.description) 
        if @video.state == "untagged"
          redirect_to "/#{'fb' if @canvas}/video/#{@video.id}/edit_tags"
        else
          redirect_to @canvas ? @video.fb_uri : @video.uri
        end
      else
        if @video.state == "untagged"
          redirect_to "/#{'fb' if @canvas}/video/#{@video.id}/edit_tags"
        else
          redirect_to "/#{@canvas ? 'fb/list' : 'video/latest'}"
        end
      end
    else
      render @canvas ? 'fb_videos/edit' : 'videos/edit'
    end
  end

  def update_tags
    redirect_to "/#{'fb/list' if @canvas}" and return unless signed_in?

    @video = Video.find(params[:id])

    logger.info "the video to update: " + @video.to_s

    existing_taggees = @video.video_taggees_uniq.map(&:id).compact

    if @video.update_attributes(params[:video])
      if new_taggees = (@video.video_taggees_uniq.map(&:id).compact - existing_taggees)
        if @video.fb_uploaded
          post_vtag(current_user.fb_graph, @new, new_taggees, @video.fb_id, @video.title.titleize, current_user)
        end  
        if @video.current_state == "tagged"
          if @video.fb_uploaded
            logger.info "---Tagged!! video is uploaded and analyzed"
            @video.done!
          else
            logger.info "---Tagged!! video is just analyzed"
            @video.tagged!
            redirect_to "/#{@canvas ? 'fb/list' : 'video/latest'}", :notice => "Successfuly updated tags"
            return
          end
        end
      end
      redirect_to @canvas ? @video.fb_uri : (@video.uri), :notice => 'Successfuly updated tags'
    else
      edit_tags
      flash[:error] = 'Error updating tags'
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

  def get_views_count
    @video = Video.find_by_fb_id(params[:fb_id])
    render :json => @video.views_count
  end

  def increment_views_count
    @video = Video.find_by_fb_id(params[:fb_id])
    @video.views_count += 1
    @video.save
    render :json => @video.views_count
  end

  private

  def check_canvas
    @canvas = params["canvas"] || params[:canvas]
  end

  def resolve_layout
    @canvas ? "fb_videos" : "application"
  end

end
