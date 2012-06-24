class VideosController < ApplicationController

  before_filter :check_canvas
  layout :resolve_layout
  before_filter :redirect_first_page_to_base, :only => [:list], :if => proc{@canvas}
  before_filter :authorize, :only => [:edit, :edit_tags]

  def show
    fb_id = params[:fb_id].to_i
    default_cut = params["default_cut"] ? params["default_cut"] : (current_user ? current_user.nick : "")
    @video = Video.for_view(fb_id)
    if !@video then render_404 and return end
    @page_title = @video.title
    check_video_redirection(@video) unless @canvas
    @user = @video.user
    @own_videos = current_user == @user ? true : false
    @video.gen_player_file default_cut if @video.analyzed
    unless @canvas
      #sidebar
      get_sidebar_data # latest
      @user_videos = Video.get_videos_by_user(1, @user.id, false, false, 3)
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
        title_part = @order.titleize
        @empty_message = "There are no videos to present for this page."
      when key = Video::CATEGORIES.key(@order)
        @videos = Video.get_videos_by_category(current_page, key)
        @category = true
        title_part = @order.titleize
        @empty_message = "There are no videos to present for this page."
      when @order == "by_user"
        @user = @canvas ? current_user : User.find(params[:id])
        @own_videos = current_user == @user ? true : false
        @videos = Video.get_videos_by_user(current_page, @user.id, @own_videos, @canvas)
        @user_videos_page = true
        title_part = @own_videos ? "My" : "#{@user.nick}'s"
        @empty_message = "This user does not have any videos yet."
      else
        render_404 and return
    end
    @page_title = "#{title_part} Videos"
    get_sidebar_data unless @canvas

    #Moozly: still 2 views
    render 'fb_videos/list' if @canvas
  end

  def vtaggees
    @page_title = "I got Vtagged"
    @vtagged_page = true
    user = current_user
    @videos = Video.find_all_by_vtagged_user(user.fb_id, @canvas)
    @empty_message = "You haven't been Vtagged Yet :-(."
    get_sidebar_data unless @canvas
    render @canvas ? 'fb_videos/vtaggees' : 'videos/list'
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
    @page_title = "Upload Video"
    #Moozly: still 2 views
    render 'fb_videos/new' if @canvas
  end

  #new video, upload to Facebook + analyze
  def create
    logger.info "---in video.create"
    unless !signed_in? || !params[:video]
      logger.info "---creating video with " + params.to_s
      more_params = {:user_id => current_user.id, :duration => 0} #temp duration
      @video = Video.new(params[:video].merge(more_params))
      @video.fb_uploaded = !@video.fb_id.nil?
      if @video.save
        @video.analyze!
        @video.delay(:queue => 'detect', :priority => 20).detect_and_convert(false)
        @video.delay(:queue => 'upload').upload_video_to_fb(10, 3, @canvas, current_user)
        #flash[:notice] = "Video has been uploaded"
        logger.info "------ New video created"
        redirect_to @canvas ? "/fb/video/#{@video.id}/edit/new" : "#{edit_video_path(@video)}/new"
      else
        flash[:notice] = "Video upload has failed :-(. Please try again"
        redirect_to @canvas ? "/fb/new" : "/videos/new"
      end
    else
      redirect_to @canvas ? "/beta" : "/fb/list"
    end
  end

  def edit
    @video = Video.find(params[:id]) # Edit expects ID not FB_ID 
    @page_title = "#{@video.title} - Edit"
    @new_one = request.path.include? "new"
    @from_analyze = params["analyze"] == "true"
    #Moozly: still 2 views
    render 'fb_videos/edit' if @canvas
  end

  #video is already on fb - vtago this video
  def analyze
    fb_id = params[:fb_id]
    @video = Video.for_view(fb_id)
    @video.fb_uploaded = true
    @video.analyze!
    @video.delay(:queue => 'detect').detect_and_convert(false)
    redirect_to @canvas ? "/fb/video/#{@video.id}/edit/new?analyze=true" : "#{edit_video_path(@video)}/new?analyze=true"
  end

  def edit_tags
    @new = request.path.include?("new") ? true : false
    @video = Video.find(params[:id])
    @page_title = "#{@video.title.titleize} - #{@new ? "Add" : "Edit"} Tags"
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
    #logger.info "The parameters for the edit tags are: " + @new.to_s + @video.to_s + @page_title.to_s + @user.to_s + @taggees.to_s + @friends.to_s + @canvas.to_s
    unless @canvas
      #sidebar
      get_sidebar_data # latest
      @user_videos = Video.get_videos_by_user(1, @user.id, false, false, 3)
      @trending_videos = Video.get_videos_by_sort(1,"popular", false, 3)
      @active_users = User.get_users_by_activity
    end
    #Moozly: still 2 views
    render (@canvas ? 'fb_videos/edit_tags' : 'videos/edit_tags')
  end

  def update_video
    redirect_to "/#{@canvas ? 'fb/list' : 'video/most_popular'}" and return unless signed_in? and params[:video]

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
          redirect_to "/#{@canvas ? "fb/list" : "users/#{current_user.id}/videos"}"
        end
      end
    else
      render @canvas ? 'fb_videos/edit' : 'videos/edit'
    end
  end

  def update_tags
    redirect_to "/#{'fb/list' if @canvas}" and return unless signed_in?
    @video = Video.find(params[:id])
    existing_taggees = @video.video_taggees_uniq.map(&:fb_id).compact
    new_taggees = []
    if @video.update_attributes(params[:video])
      @video.video_taggees_uniq.each do |taggee|
        if taggee.time_segments.count == 0
          taggee.init_empty_taggee
        end
        new_taggees << taggee unless (existing_taggees.include?(taggee.fb_id) || !taggee.fb_id || (taggee.fb_id == current_user.fb_id))
      end
      if new_taggees.any? #new_taggees = (@video.video_taggees_uniq.map(&:id).compact - existing_taggees)
        @video.update_time_to_now
        if @video.fb_uploaded
          post_vtag(current_user.fb_graph, @new, new_taggees, @video.fb_id, @video.title.titleize, current_user) unless @video.private
          new_taggee_fb_ids = new_taggees.map(&:fb_id)
          @video.create_vtagged_notifications(new_taggee_fb_ids)
        end  
        if @video.current_state == "tagged"
          if @video.fb_uploaded
            logger.info "---Tagged!! video is uploaded and analyzed"
            @video.done!
          else
            logger.info "---Tagged!! video is just analyzed"
            @video.tagged!
            redirect_to "/#{@canvas ? 'fb/list' : 'video/vtaggees'}", :notice => "Successfuly updated tags"
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

  def hide
    vid = Video.find_by_fb_id(params[:fb_id])
    vid.hide
    redirect_to !@canvas ? "/" : "/fb/list"
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

  def search
     @page_title = "Search Results"
    get_sidebar_data
    render "application/search_results"
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

  def analyze_count
    num_of_pendings = current_user ? Video.number_of_pending_videos(current_user.id) : 0
    render :json => num_of_pendings
  end

  private

  def check_canvas
    @canvas = params["canvas"] || params[:canvas]
  end

  def resolve_layout
    @canvas ? "fb_videos" : "application"
  end
end
