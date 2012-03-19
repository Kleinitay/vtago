class AddSrcIdToVideoAndRenameFbId < ActiveRecord::Migration
  def self.up
    add_column    :videos, :src_id, :integer
    rename_column :videos, :fbid, :fb_id
  end

  def self.down
    remove_column :videos, :src_id
    rename_column :videos, :fb_id, :fbid
  end
end

#src_id
# 1 => vtago
# 2 => Facebook
