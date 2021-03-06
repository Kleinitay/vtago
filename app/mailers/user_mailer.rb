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
end