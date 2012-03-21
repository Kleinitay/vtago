class AddFbThumbToVideos < ActiveRecord::Migration
  def self.up
    add_column    :videos, :fb_thumb, :string
  end
  def self.down
    remove_column :videos, :fb_thumb
  end
end
