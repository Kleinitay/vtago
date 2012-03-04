class AddIndexToVideosByCategory < ActiveRecord::Migration
  def self.up
      add_index(:videos, :category, :name => 'by_category')
    end

    def self.down
      remove_index(:videos, :name => 'by_category')
    end
end
