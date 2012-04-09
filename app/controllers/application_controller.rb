class ApplicationController < ActionController::Base
  include Clearance::Authentication
  include helper::FacebookHelper
  #protect_from_forgery Moozly: disabling for Facebook -Koala
  
  before_filter :clear_notification

  def home
    url = signed_in? ? "/video/latest" : "/auth/facebook"
    redirect_to(url)
  end

  def render_404
      render(:file => "#{Rails.root}/public/404.html", :status => 404)
  end

  def about
    @page_title = "About VtagO"
  end

  #Moozly: for controllers of listing. Redirecting /1 to no parameter.
  def redirect_first_page_to_base
    if params[:page] == '1'
      uri = request.path
      redirect_to(uri.gsub("/1",""))
    end
  end

  def clear_notification
    return unless notification_id = params[:notif] and signed_in?

    if notification = Notification.where(:id => notification_id).first
      Rails.logger.info "Notification #{notification} has been pressed"
      notification.mark_viewed!
    end
  end
end
