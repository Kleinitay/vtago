source :rubygems
HOST_OS = RbConfig::CONFIG['host_os']

gem 'rails', '3.0.9'
gem 'clearance'
gem 'permalink_fu', '~> 1.0.0'
gem 'annotate', '2.4.0'
gem 'acts_as_state_machine'
gem 'mysql2', '< 0.3'
gem 'will_paginate', '~> 3.0'
gem 'koala'
gem 'jquery-rails', '>= 1.0.12'
gem 'omniauth-facebook'
gem 'carrierwave'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'fog'
gem 'aws-s3'
gem 'exception_notification'
gem 'browser'
gem 'face'
gem 'curltube'
gem 'youtube_it'
gem 'foreman'
#for rubymine
#gem 'linecache19'
#gem 'ruby-debug-ide'
#gem 'ruby-debug-base19x'

group :development, :test do
  gem 'bullet'
  gem 'ruby-debug19'
  gem "rspec-rails"
end
gem "rubber", "1.15.0"

group :development do
  gem "guard", ">= 0.6.2"
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
  gem 'query_reviewer', :git => "git://github.com/nesquena/query_reviewer.git"
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
