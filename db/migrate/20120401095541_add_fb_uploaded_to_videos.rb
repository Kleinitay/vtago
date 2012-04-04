class AddFbUploadedToVideos < ActiveRecord::Migration
  def self.up
     add_column   :videos, :fb_uploaded, :boolean
  end

  def self.down
    remove_column :videos, :fb_uploaded
  end
end
