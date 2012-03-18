class AddUploaderToVideoTaggee < ActiveRecord::Migration
  def self.up
    add_column :video_taggees, :TaggeeFace, :string
  end

  def self.down
    remove_column :video_taggees, :TaggeeFace
  end
end
