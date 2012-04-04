module Amazon
  config_path = File.join(Rails.root, "config", "s3.yml")
  CONFIG = YAML.load_file(config_path)[Rails.env]
  KEY    = CONFIG['key']
  SECRET = CONFIG['secret']
  BUCKET = CONFIG['bucket']
end

CarrierWave.configure do |config|
  config.permissions = 0777
  config.s3_access_key_id = Amazon::KEY
  config.s3_secret_access_key = Amazon::SECRET
  config.s3_bucket = Amazon::BUCKET

  config.fog_credentials = {
    :provider               => 'AWS',
    :aws_access_key_id      => Amazon::KEY,
    :aws_secret_access_key  => Amazon::SECRET,
  }
  config.fog_directory  = Amazon::BUCKET
end
