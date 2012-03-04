class AddColumnsToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :duration, :integer, :null => false
    add_column :videos, :category, :integer, :null => false  # List in CommonData[:video_categories]
    add_column :videos, :description, :string
    add_column :videos, :keywords, :string
  end

  def self.down
    remove_column :videos, :duration
    remove_column :videos, :category
    remove_column :videos, :description
    remove_column :videos, :keywords
  end
end
