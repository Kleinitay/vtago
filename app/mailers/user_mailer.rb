class UserMailer < ActionMailer::Base
  default :from => "subscribe@vtago.com"

  def registration_confirmation(user)
    @user = user
    mail(:to => user.email, :subject => "Welcome to VtagO", :content_type => "text/html")
  end

  def email_subscribe(email)
    mail(:to => email, :subject => "Your invite request by VtagO", :content_type => "text/html")
  end

  def email_subscribe_notification(email)
    @email = email
    mail(:to => "subscribe@vtago.com", :subject => "New e-mail subscriber", :content_type => "text/html")
  end

  def email_analysis_done(user, video)
    @title = video.title
    @link = "#{Rails.env.production? ? "www.vtago.com" : "example.com"}/video/#{video.id}/edit_tags/new"
    logger.info "--------------mailing #{video.title} to #{user.email}"
    mail(:to => user.email, :subject => "Your video #{video.title} is ready to be tagged", :content_type => "text/html")
  end
  
  def email_analyse_all_done(user)
    @link = "#{Rails.env.production? ? "www.vtago.com" : "example.com"}//users/#{user.id}/videos"
     mail(:to => user.email, :subject => "Your facebook videos are ready for tagging", :content_type => "text/html")
  end

  def email_exception(ex)
    @exception = ex.message + "  " + ex.backtrace.join("\n")
    mail(:to => "itay@vtago.com", :subject => "Error accured - read this!!!", :content_type => "text/html")
  end

end