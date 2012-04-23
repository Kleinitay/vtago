class UserMailer < ActionMailer::Base
  default :from => "subscribe@vtago.com"

  def registration_confirmation(user)
    #@user = user
    mail(:to => user.email, :subject => "Registered")
  end

  def email_subscribe(email)
    mail(:to => email, :subject => "Registered")
  end
end