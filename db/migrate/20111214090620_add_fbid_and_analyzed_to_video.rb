class AddFbidAndAnalyzedToVideo < ActiveRecord::Migration
  def self.up
    add_column :videos, :fbid, :string
    add_column :videos, :analyzed, :boolean
  end

  def self.down
    remove_column :videos, :analyzed
    remove_column :videos, :fbid
  end
end
