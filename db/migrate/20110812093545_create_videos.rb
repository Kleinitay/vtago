class CreateVideos < ActiveRecord::Migration
  def self.up
  	 create_table :videos do |t|
      t.column "user_id",       :integer, :null => false
      t.column "title",         :string
      t.column "views_count",   :integer, :default => 0
      t.timestamps
     end
     
     add_index(:videos, :user_id, :name => 'by_user_id')
  end
  
  def self.down
  	 drop_table :videos
  end
end
