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
#  type_id    :integer(4)
#

# type_id :
#   1 => video ready
#   2 => got your fb videos
#   3 => you got vtagged

class Notification < ActiveRecord::Base
  belongs_to :video
  belongs_to :user

  validates_presence_of :type_id, :message, :user_id

  scope :unviewed, lambda { where(:viewed => false) }

  default_scope :order => 'viewed ASC, created_at DESC'

  after_create :add_to_facebook

  def link
    case type_id
      when 1 #video ready
        "/video/#{self.video.id}/edit_tags/new?notif=#{self.id}"
      when 2 #got_your_fb_videos
        "/users/#{self.user_id}/videos?notif=#{self.id}"
      when 3 #you got vtagged
        "/video/#{self.video.fb_id}?notif=#{self.id}&default_cut=#{self.user.nick}"
    end
  end

  def fb_link
    case type_id
      when 1 #video ready
  	    "/fb/video/#{self.video.id}/edit_tags/new?notif=#{self.id}"
  		when 2 #got_your_fb_videos
        "http://www.vtago.com/fb/list"
    	when 3  #you got vtagged
        "http://www.vtago.com/fb/video/#{self.video.fb_id}?default_cut=#{self.user.nick}"
  	end
  end

  def mark_viewed!
    unless viewed 
      update_attributes(:viewed => true)
      Fb.remove_notification(user.fb_graph, fb_id) if fb_id
    end
  end

  private
    def add_to_facebook
      req_id = Fb.send_notification(user.fb_graph, user.fb_id, message, self.fb_link)
      update_attributes(:fb_id => req_id)
    end
end
