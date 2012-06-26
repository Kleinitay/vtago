class ApplicationController < ActionController::Base
  include Clearance::Authentication
  include helper::FacebookHelper
  #protect_from_forgery Moozly: disabling for Facebook -Koala
  
  before_filter :clear_notification

  def home
    url = signed_in? ? "/video/latest" : "/sign_in"
    redirect_to(url)
  end

  def beta
    url = signed_in? ? "/video/latest" : "/sign_in"
    redirect_to(url)
  end

  def render_404
      render(:file => "#{Rails.root}/public/404.html", :status => 404)
  end

  def about
    # Still 2 views...
    @fb_og_title = @page_title = "About VtagO"
    @fb_og_description = "The app that gives a new meaning to video sharing."
    render 'fb_videos/about' if @canvas
  end

  def toc
    @fb_og_title = @page_title = "Terms of Use"
    @fb_og_description = "rules and policies"
  end

  #Moozly: for controllers of listing. Redirecting /1 to no parameter.
  def redirect_first_page_to_base
    if params[:page] == '1'
      uri = request.path
      redirect_to(uri.gsub("/1",""))
    end
  end

  def clear_notification
    return unless signed_in?

    fb_req   = params[:request_ids]
    notif_id = params[:notif]

    # Clear notification if pressed in app
    if notif_id and notification = Notification.where(:id => notif_id).first
      Rails.logger.info "---Notification #{notification} has been pressed on site"
      notification.mark_viewed!
    end

    # Clear notification if pressed in facebook
    if fb_req and notification = Notification.where(:fb_id => fb_req).first
      Rails.logger.info "---Notification #{notification} has been pressed in facebook"
      notification.mark_viewed!
    end
  end
end
