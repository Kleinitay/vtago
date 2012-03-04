class ReplacePaperclipWithCarrierwaveForVideo < ActiveRecord::Migration
  def self.up
      remove_column :videos, :source_content_type
      remove_column :videos, :source_file_name
      remove_column :videos, :source_file_size
      add_column :videos, :video_file, :string
  end

  def self.down
      add_column :videos, :source_content_type, :string
      add_column :videos, :source_file_name, :string
      add_column :videos, :source_file_size, :string
      remove_column :videos, :video_file
  end
end
