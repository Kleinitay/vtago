class AddFilenameToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :filename, :text
  end

  def self.down
    remove_column :videos, :filename
  end
end
