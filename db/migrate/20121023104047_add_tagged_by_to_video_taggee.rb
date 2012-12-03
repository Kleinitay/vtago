class AddTaggedByToVideoTaggee < ActiveRecord::Migration
  def self.up
    add_column :video_taggees, :tagged_by, :integer
  end

  def self.down
    remove_column :video_taggees, :tagged_by
  end
end
