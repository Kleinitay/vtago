class RemoveSrcIdAndAnalyzedFromVideos < ActiveRecord::Migration
  def self.up
    remove_column :videos, :src_id
    remove_column :videos, :analyzed
  end

  def self.down
    add_column    :videos, :src_id, :integer
    add_column    :videos, :analyzed, :boolean
  end
end
