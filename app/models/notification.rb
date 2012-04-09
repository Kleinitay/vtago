class Notification < ActiveRecord::Base
  belongs_to :video
  belongs_to :user

  validates_presence_of :message, :user_id

  scope :unviewed, lambda { where(:viewed => false) }

  default_scope :order => 'viewed ASC, created_at DESC'

  after_create :add_to_facebook

  def mark_viewed!
    update_attributes(:viewed => true)
    Fb.remove_notification(fb_graph(user.fb_token), fb_id) if fb_id
  end

  private
    def add_to_facebook
      req_id = Fb.send_notification(fb_graph(user.fb_token), user.fb_id, video.fb_id, video.title, message)
      update_attributes(:fb_id => req_id)
    end
end
