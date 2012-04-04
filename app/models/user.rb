# == Schema Information
#
# Table name: users
#
#  id                 :integer(4)      not null, primary key
#  email              :string(255)     not null
#  password           :string(255)
#  nick               :string(255)
#  fb_id              :integer(8)
#  created_at         :datetime
#  updated_at         :datetime
#  encrypted_password :string(128)
#  salt               :string(128)
#  confirmation_token :string(128)
#  remember_token     :string(128)
#  status             :integer(4)      not null
#  profile_pic        :string(255)
#  fb_token           :string(255)
#

require 'carrierwave/orm/activerecord'

class User < ActiveRecord::Base
  include Clearance::User
  
  has_many :videos, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :authentications, :dependent => :destroy
  has_many :notifications, :dependent => :destroy

  validates_presence_of :nick, :message => "must be entered."
  validates_uniqueness_of :nick, :message => "already taken."

  mount_uploader :profile_pic, ProfilePicUploader

#--------------------- Global params --------------------------
  FULL_USER_IMG_PATH = "#{Rails.root.to_s}/public/images/users/"
  USER_IMG_PATH = "/images/users/"
  IMG_PATH_PREFIX = "#{Rails.root.to_s}/public"
  DEFAULT_PROFILE_IMG = "#{USER_IMG_PATH}default_profile.png"
#------------------------------------------------------ Instance methods -------------------------------------------------------

  def save_fb_videos
    videos = fb_graph.get_connections(self.fb_id,'videos/uploaded?limit=1000')
    existing_ids = Video.find_all_by_user_id(self.id, :select => "fb_id").map(&:fb_id)
    videos_to_add = []
    if videos.any?
      videos.each do |v|
        unless existing_ids.include?(v["id"])
          video_str = ActiveRecord::Base.send(:sanitize_sql, ["(?, ?, ?, ?, ?, ?, ?, ?, ?)",
                      self.id,                        # user id
                      v["id"],                        # fb_id
                      0,                              # duration
                      v["name"] || v['created_time'], # title
                      v["description"],               # description
                      v["source"],                    # fb_src
                      v["created_time"],              # created_at
                      20,                             # category
                      v["picture"]], '')              # fb_thumb
          videos_to_add << video_str
        end
      end
      columns = "(user_id,fb_id,duration,title,description,fb_src,created_at,category,fb_thumb)"
      values = videos_to_add.join(",")
      connection.execute("insert into videos #{columns} VALUES #{values};");
    end #if any videos
  end

  def fb_graph
    Koala::Facebook::API.new(self.fb_token)
  end

#------------------------------------------------------ Class methods -------------------------------------------------------
  def self.profile_pic_directory(user_id)
    string_id = (user_id.to_s).rjust(9,"0")
    "#{USER_IMG_PATH}#{string_id[0..2]}/#{string_id[3..5]}/#{string_id[6..8]}"
  end
  
  def self.profile_pic_full_directory(user_id)
    string_id = (user_id.to_s).rjust(9,"0")
    "#{FULL_USER_IMG_PATH}#{string_id[0..2]}/#{string_id[3..5]}/#{string_id[6..8]}"
  end

  def self.profile_pic_src(user_id)
    user = User.find_by_id(user_id)
    pic_path = user.profile_pic.url #"#{User.profile_pic_directory(user_id)}/profile.jpg"
    (FileTest.exists? "#{IMG_PATH_PREFIX}#{pic_path}") ? pic_path : DEFAULT_PROFILE_IMG
  end

  def self.get_users_by_activity
    #Moozly: updae to users with latest video till a week ago + no zeros...
    User.find_by_sql("select users.id, nick, count(user_id) as videos_num from videos, users where videos.user_id = users.id group by videos.user_id order by videos_num desc limit 3;")
  end
end
