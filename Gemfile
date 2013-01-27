source :rubygems
HOST_OS = RbConfig::CONFIG['host_os']

gem 'rails', '3.0.9'
gem 'clearance' #login
gem 'permalink_fu', '~> 1.0.0' #make links pretty
gem 'annotate', '2.4.0' #write field names at top of model file 
gem 'acts_as_state_machine' #state machine for video analysis
gem 'mysql2', '< 0.3' 
gem 'will_paginate', '~> 3.0'
gem 'koala' #facebook gem
gem 'jquery-rails', '>= 1.0.12'
gem 'omniauth-facebook'
gem 'carrierwave' #file storage
gem 'delayed_job_active_record' #queue of jobs
gem 'daemons'
gem 'fog' #s3
gem 'aws-s3'
gem 'exception_notification' #sends e-mail for notifications
gem 'browser' #check browser type
gem 'face' 
gem 'curltube' #download videos from youtube
gem 'youtube_it' #youtube api
gem 'foreman' #running processes
gem 'pg'

#for rubymine
#gem 'linecache19'
#gem 'ruby-debug-ide'
#gem 'ruby-debug-base19x'

group :development, :test do
  gem 'bullet' #qurey optimizer 
  gem 'ruby-debug19'
  gem "rspec-rails" 
end
gem "rubber", "1.15.0" #deployment on ec2

group :development do
  gem "guard", ">= 0.6.2" #automatic updates
  case HOST_OS
    when /darwin/i
      gem 'rb-fsevent'
      gem 'growl'
    when /linux/i
      gem 'libnotify'
      gem 'rb-inotify'
    when /mswin|windows/i
      gem 'rb-fchange'
      gem 'win32console'
      gem 'rb-notifu'
  end
  gem 'query_reviewer', :git => "git://github.com/nesquena/query_reviewer.git" #query optimizer
  gem "guard-bundler", ">= 0.1.3"
  gem "guard-rails", ">= 0.0.3"
  gem "guard-livereload", ">= 0.3.0"
  gem "guard-rspec", ">= 0.4.3"
  gem "pry-rails"
  gem "nifty-generators"
end

group :test do
  gem "database_cleaner", ">= 0.7.0"
  gem "factory_girl_rails", ">= 1.4.0"
  gem "capybara", ">= 1.1.2"
  gem "email_spec"
end
