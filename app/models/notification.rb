# == Schema Information
#
# Table name: notifications
#
#  id         :integer(4)      not null, primary key
#  viewed     :boolean(1)      default(FALSE)
#  message    :text
#  video_id   :integer(4)
#  user_id    :integer(4)
#  fb_id      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Notification < ActiveRecord::Base
  belongs_to :video
  belongs_to :user

  validates_presence_of :message, :user_id

  scope :unviewed, lambda { where(:viewed => false) }

  default_scope :order => 'viewed ASC, created_at DESC'

  after_create :add_to_facebook

  def mark_viewed!
    unless viewed 
      update_attributes(:viewed => true)
      Fb.remove_notification(user.fb_graph, fb_id) if fb_id
    end
  end

  private
    def add_to_facebook
      req_id = Fb.send_notification(user.fb_graph, user.fb_id, video.fb_id, video.title, message)
      update_attributes(:fb_id => req_id)
    end
end
