class AddHiddenToVideo < ActiveRecord::Migration
  def self.up
    add_column :videos, :hidden, :boolean
  end

  def self.down
    remove_column :videos, :hidden
  end
end
