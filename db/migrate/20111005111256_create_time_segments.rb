class CreateTimeSegments < ActiveRecord::Migration
  def self.up
    create_table :time_segments do |t|
      t.integer :taggee_id
      t.integer :begin
      t.integer :end

      t.timestamps
    end
  end

  def self.down
    drop_table :time_segments
  end
end
