class RenameFbUploadedToUploadedInVideos < ActiveRecord::Migration
  def self.up
    rename_column :videos, :fb_uploaded, :uploaded
  end

  def self.down
    rename_column :videos, :uploaded, :fb_uploaded
  end
end
