class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column "email",       :string, :null => false, :unique => true
      t.column "password",    :string
      t.column "nick",        :string
      t.column "fb_id",       :string, :unique => true
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
