class AddProfilePicToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :profile_pic, :string
  end

  def self.down
    remove_column :users, :profile_pic
  end
end
