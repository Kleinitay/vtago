class AddAnalyzedAgainToVideos < ActiveRecord::Migration
  def self.up
    add_column    :videos, :analyzed, :boolean, :default => false
  end

  def self.down
    remove_column :videos, :analyzed
  end
end
