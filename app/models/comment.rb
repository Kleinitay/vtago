# == Schema Information
#
# Table name: comments
#
#  id         :integer(4)      not null, primary key
#  content    :text
#  video_id   :integer(4)      not null
#  user_id    :integer(4)      not null
#  status     :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :video

  validates_uniqueness_of :content, :scope => [:video_id], :message => "already exists for this video."
  validates_length_of :content, :minimum => 1, :message => "can't be empty."


  def self.get_user_comments(user_id)
    Comment.all(:user_id => user_id, :limit => 10)
  end

  def self.get_video_comments(video_id)
    comments = Comment.find_by_sql("select comments.*, users.nick from comments, users where comments.user_id = users.id and video_id=#{video_id} order by created_at desc;")
    total_comments_count = ActiveRecord::Base.connection.select_value("SELECT FOUND_ROWS();").to_i
    [comments, total_comments_count]
  end
  
end
