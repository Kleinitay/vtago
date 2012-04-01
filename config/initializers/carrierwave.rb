module Amazon
  config_path = File.join(Rails.root, "config", "amazon.yml")
  CONFIG      = YAML.load_file(config_path)[Rails.env]
  KEY         = CONFIG['key']
  SECRET      = CONFIG['secret']
  BUCKET      = CONFIG['bucket']
  FOLDER      = CONFIG['folder']
end

CarrierWave.configure do |config|
  config.permissions = 0777
  config.s3_access_key_id = Amazon::KEY
  config.s3_secret_access_key = Amazon::SECRET
  config.s3_bucket = Amazon::BUCKET
end
