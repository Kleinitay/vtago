class AddVideoThumbnailToVideo < ActiveRecord::Migration
  def self.up
    add_column :videos, :video_thumbnail, :string
  end

  def self.down
    remove_column :videos, :video_thumbnail
  end
end
