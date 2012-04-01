class ChangeFbIdDataTypeInAllModels < ActiveRecord::Migration
  def self.up
    change_column :videos,        :fb_id, :bigint
    change_column :video_taggees, :fb_id, :bigint
    change_column :users,         :fb_id, :bigint
  end

  def self.down
    change_column :videos,        :fb_id, :string
    change_column :video_taggees, :fb_id, :integer
    change_column :users,         :fb_id, :string
  end
end
