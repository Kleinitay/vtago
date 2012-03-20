class AddFbSrcToVideos < ActiveRecord::Migration
  def self.up
     add_column    :videos, :fb_src, :string
  end

  def self.down
    remove_column    :videos, :fb_src
  end
end