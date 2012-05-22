class AddTypeIdToNotifications < ActiveRecord::Migration
  def self.up
    add_column    :notifications, :type_id, :integer
  end

  def self.down
    remove_column :notifications, :type_id
  end
end
