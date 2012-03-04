class UsersController < ApplicationController

  before_filter :redirect_first_page_to_base
  before_filter :authorize_admins, :only => [:index, :edit]

  # GET /users
  # GET /users.xml
  def index
    @users = User.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    if signed_in? && current_user.id == params[:id] || (["elinor.dreamer@gmail.com", "klein.itay@gmail.com"].include? current_user.email)
      @user = User.find(params[:id])
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @user }
      end
    else
      redirect_to "/"
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    render_404
    #@user = User.new
    #respond_to do |format|
    #  format.html # new.html.erb
    #  format.xml  { render :xml => @user }
    #end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.xml
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

  # PUT /users/1
  # PUT /users/1.xml
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

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end
  
  def videos
    @user = User.find(params[:id])
    if !@user then render_404 and return end
    current_page = (params[:page] == "0" ? "1" : params[:page]).to_i
    @user_videos_page = true
    @own_videos = current_user == @user ? true : false
    @page_title = @own_videos ? "My" : "#{@user.nick}'s"
    @empty_message = "This user does not have any videos yet."
    @videos = Video.get_videos_by_user(current_page,@user.id, false)
    get_sidebar_data # latest
    render "/videos/user_videos_list"
  end
  
  
  def get_sidebar_data
    @sidebar_order = "latest"
    @sidebar_list_title = "Latest Ones"
    @sidebar_videos = Video.get_videos_by_sort(1,@sidebar_order, true ,3)
    @trending_videos = Video.get_videos_by_sort(1,"popular", true ,3)
    @active_users = User.get_users_by_activity
  end
end
