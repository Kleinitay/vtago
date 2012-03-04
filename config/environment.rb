# Load the rails application
require File.expand_path('../application', __FILE__)

CommonData = YAML::load(File.read('config/common_data.yml'))

# Initialize the rails application
Dreamline::Application.initialize!

Dreamline::Application.configure do
    config.action_controller.allow_forgery_protection = false
    config.gem "koala"
end

# for Facebook Connect
FB_APP_KEY = Facebook::APP_ID
FB_APP_SECRET = "2eab4df3fb3f1397d6f6ddca929db4af"
FB_APP_ID = Facebook::APP_ID
FB_SITE_URL = "localhost:3000/" #temp => http:www.vtago.com


