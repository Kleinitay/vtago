Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook,  Facebook::APP_ID,  Facebook::SECRET, {:scope => 'publish_stream, email, offline_access, user_videos, video_upload', :client_options => {:ssl => {:ca_file => "#{Rails.root}/config/ca"}}}
end