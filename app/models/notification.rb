class Notification < ActiveRecord::Base
  belongs_to :video

  validates_presence_of :message, :user_id

  scope :unviewed, lambda { where(:viewed => false) }

  default_scope :order => 'viewed ASC, created_at DESC'

  def mark_viewed!
    update_attributes(:viewed => true)
  end
end
