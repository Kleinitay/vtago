class AddTokenExpiresAtToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :token_expires_at, :datetime
  end

  def self.down
    remove_column :users, :token_expires_at
  end
end
