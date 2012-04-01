class AddUploaderToVideoTaggee < ActiveRecord::Migration
  def self.up
    add_column :video_taggees, :taggee_face, :string
  end

  def self.down
    remove_column :video_taggees, :taggee_face
  end
end
