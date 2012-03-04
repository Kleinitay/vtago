class CreateVideoTaggees < ActiveRecord::Migration

  def self.up
    create_table :video_taggees do |t|
      t.column "contact_info",  :string, :null => false # name or user id
      t.column "fb_id",         :integer
      t.column "video_id",      :string, :null => false
      t.column "created_at",    :datetime
      t.timestamps
    end
  end

  def self.down
    drop_table :video_taggees
  end
end
