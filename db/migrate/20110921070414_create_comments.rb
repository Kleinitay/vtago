class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.column :content, :text, :null => false
      t.column :video_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :status, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :comments
  end
end

# status:
# 1 temp
# 2 published
# 3 hidden