class ApplicationController < ActionController::Base
  include Clearance::Authentication
  include helper::FacebookHelper
  #protect_from_forgery Moozly: disabling for Facebook -Koala

  def home
    url = signed_in? ? "/video/latest" : "/sign_in"
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
end
