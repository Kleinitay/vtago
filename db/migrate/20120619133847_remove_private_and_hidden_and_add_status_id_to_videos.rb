class RemovePrivateAndHiddenAndAddStatusIdToVideos < ActiveRecord::Migration
  def self.up
    remove_column :videos, :private
    remove_column :videos, :hidden
    add_column :videos, :status_id, :integer, :null => false, :default => 1
  end

  def self.down
    add_column :videos, :private, :boolean
    add_column :videos, :hidden, :boolean
    remove_column :videos, :status_id
  end
end

#status:
# 0 = hidden
# 1 = public
# 2 = private