class CreateEmailSubscribedUsers < ActiveRecord::Migration
  def self.up
    create_table :email_subscribed_users do |t|
      t.column "email", :string, :null => false, :unique => true
      t.timestamps
    end    
  end

  def self.down
     drop_table :users
  end
end
