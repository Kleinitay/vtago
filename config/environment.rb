# Load the rails application
require File.expand_path('../application', __FILE__)

CommonData = YAML::load(File.read('config/common_data.yml'))
Urls = CommonData[Rails.env]

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Initialize the rails application
Dreamline::Application.initialize!

Dreamline::Application.configure do
    config.action_controller.allow_forgery_protection = false
    config.gem "koala"
end

TEMP_DIR_FULL_PATH = "#{Rails.root}/public/tmp"
VIDEO_BUCKET = "vtago_videos"
AWS_KEY = 'AKIAJLFBBEDDLZFLJ4DA'
AWS_SECRET = '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'


