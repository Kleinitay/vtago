class AddColumnStatusToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :status, :integer, :null => false  # List in CommonData[:user_status]
  end

  def self.down
    remove_column :videos, :duration
  end
end
