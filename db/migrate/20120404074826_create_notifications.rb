# -*- encoding : utf-8 -*-
class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.boolean :viewed, :default => false
      t.text :message
      t.integer :video_id
      t.integer :user_id
      t.string :fb_id

      t.timestamps
    end
  end

  def self.down
    drop_table :notifications
  end
end
