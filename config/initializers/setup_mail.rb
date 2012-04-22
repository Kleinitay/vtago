ActionMailer::Base.smtp_settings = {
      :address              => "smtp.gmail.com",
      :port                 =>  587,
      :domain               => "vtago.com",
      :user_name            => "subscribe@vtago.com", #Your user name
      :password             => "danistavi", # Your password
      :authentication       => "plain",
      :enable_starttls_auto => true
   }