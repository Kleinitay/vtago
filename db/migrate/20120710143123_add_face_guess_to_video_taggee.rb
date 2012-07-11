class AddFaceGuessToVideoTaggee < ActiveRecord::Migration
  def self.up
    add_column :video_taggees, :face_guess, :bigint
  end

  def self.down
    remove_column :video_taggees, :face_guess
  end
end
