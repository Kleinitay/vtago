class AddThumbnailToVideo < ActiveRecord::Migration
  def self.up
    add_column :video_taggees, :thumbnail, :string
  end

  def self.down
    remove_column :video_taggees, :thumbnail
  end
end
