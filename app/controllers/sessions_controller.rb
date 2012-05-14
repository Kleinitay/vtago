#### Remove this one??? #######
class SessionsController < ApplicationController
  unloadable
 # attr_accessor access_token

  skip_before_filter :authorize, :only => [:new, :create, :destroy]
  #protect_from_forgery :except => :create

  def new
    @page = "signin"
  end
  def create
    @user = authenticate(params)
    if @user.nil?
      flash_failure_after_create
      render :template => 'users/sessions/new', :status => :unauthorized
    else
      sign_in(@user)
      redirect_back_or(url_after_create)
    end
  end

  def email_subscribe
    email = params[:session][:email]
    @new_sub = EmailSubscribedUser.create(:email => email)
    unless @new_sub.errors.any?
      UserMailer.email_subscribe(email).deliver
      UserMailer.email_subscribe_notification(email).deliver
    end
    render "application/home_thank_you", :layout => "landing"
  end

  def destroy
    sign_out
    begin
      fb_id = fb_oauth.get_user_from_cookies(cookies)
      url = fb_id ? fb_logout_url : url_after_destroy
    rescue
      cookies.each { |x,v| cookies.delete(x) }
      #cookies.delete_all
      #render :text => "Session Has gone away. Please refresh and try again."
    end  
    url = url_after_destroy
    redirect_to(url)
  end

  def aoth_athenticate
    redirect_to("https://www.facebook.com/dialog/aouth?client_id=#{Facebook::APP_ID}&redirect_uri=#{Facebook::site_url}/aoth_return")
  end

  def aoth_authenticate_return
    code = params[:code]
    access_token = params[:access_token]
    expires = params[:expires]
    if code
      redirect_to("https://graph.facebook.com/oauth/access_token?client_id=#{APP_ID}&redirect_uri=#{Facebook::site_url}/session/aoth_authenticate_return&client_secret=#{APP_SECRET}&code=#{code}")
    else
      access_token
    end
  end

  private

  def flash_failure_after_create
    flash.now[:notice] = translate(:bad_email_or_password,
      :scope   => [:clearance, :controllers, :sessions],
      :default => "Bad email or password.")
  end

  def url_after_create
    '/'
  end

  def url_after_destroy
    sign_in_url
  end


end