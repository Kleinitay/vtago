class UsersController < ApplicationController

  before_filter :redirect_first_page_to_base
  before_filter :authorize_admins, :only => [:index, :edit]

  def index
    @users = User.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  def show
    if signed_in? && current_user.id == params[:id] || (["elinor.dreamer@gmail.com", "klein.itay@hotmail.com"].include? current_user.email)
      @user = User.find(params[:id])
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @user }
      end
    else
      redirect_to "/"
    end
  end

  def new
    render_404
    #@user = User.new
    #respond_to do |format|
    #  format.html # new.html.erb
    #  format.xml  { render :xml => @user }
    #end
  end

  def edit
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(params[:user])
    @user.status = 2 #for now active, later change to 1 - pre active
    respond_to do |format|
      if @user.save
        format.html { redirect_to(@user, :notice => 'User was successfully created.') }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to(@user, :notice => 'User was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def authorize_admins
    unless (["elinor.dreamer@gmail.com", "klein.itay@gmail.com"].include? current_user.email)
      render_404 and return
    end
  end

  def destroy
    @user = User.find(params[:id])
    logger.info "-----destroying user"
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end

  def sync_fb_videos
    user = User.find(params[:id])
    if user
      user.sync_fb_videos
    end
    redirect_to "/users/#{user.id}/videos"
  end

  def get_sidebar_data
    @sidebar_order = "latest"
    @sidebar_list_title = "Latest Ones"
    @sidebar_videos = Video.get_videos_by_sort(1,@sidebar_order, false, 3)
    @trending_videos = Video.get_videos_by_sort(1,"popular", false, 3)
    @active_users = User.get_users_by_activity
  end
end
