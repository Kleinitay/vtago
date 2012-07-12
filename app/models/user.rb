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
  
  def sync_fb_videos
    videos = fb_graph.get_connections(self.fb_id,'videos/uploaded?limit=1000')
    fb_video_ids = videos.map{|v| v["id"].to_i}
    existing_ids = Video.find_all_by_user_id(self.id, :select => "fb_id, category,keywords").map(&:fb_id)
    video_ids_to_delete = existing_ids - fb_video_ids
    connection.execute("delete from videos where fb_id in (#{video_ids_to_delete.join(',')});") if video_ids_to_delete.any?
    videos_to_add = []
    if videos.any?
      videos.each do |v|
        unless existing_ids.include?(v["id"].to_i)
          video_str = ActiveRecord::Base.send(:sanitize_sql, ["(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                      self.id,                        # user id
                      v["id"],                        # fb_id
                      0,                              # duration
                      v["name"] || v['created_time'], # title
                      v["description"],               # description
                      v["source"],                    # fb_src
                      v["created_time"],              # created_at
                      1,                              # category
                      true,                           # fb_uploaded
                      "pending",                      # state
                      v["picture"]], '')              # fb_thumb
          videos_to_add << video_str
        end
      end
      if videos_to_add.any?
        columns = "(user_id,fb_id,duration,title,description,fb_src,created_at,category,fb_uploaded,state,fb_thumb)"
        values = videos_to_add.join(",")
        connection.execute("insert into videos #{columns} VALUES #{values};")
      end
    end #if any videos
  end

  def fb_graph
    @graph ||= Koala::Facebook::API.new(self.fb_token)
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

  def self.profile_pic_s3_directory(user_id)
    string_id = (user_id.to_s).rjust(9,"0")
    "profile_pics/#{string_id}"
  end

  def self.profile_pic_src(user_id)
    user = User.find_by_id(user_id)
    user.profile_pic.url #"#{User.profile_pic_directory(user_id)}/profile.jpg"
    #(FileTest.exists? "#{IMG_PATH_PREFIX}#{pic_path}") ? pic_path : DEFAULT_PROFILE_IMG
  end

  def self.get_users_by_activity
    #Moozly: updae to users with latest video till a week ago + no zeros...
    User.find_by_sql("select users.id, nick, count(user_id) as videos_num from videos, users where videos.user_id = users.id and videos.analyzed=true group by videos.user_id order by videos_num desc limit 3;")
  end
  
  def analyze_all_fb_videos
    videos = Video.where("user_id=:id AND state=:state", :id => id, :state => "pending")
    videos.each do |vid|
      vid.detect_and_convert nil 
    end
  end

  def set_face_com_creds(face_com_client)
    face_com_client.facebook_credentials = { :fb_user => fb_id, :oauth_token => fb_token }
  end
end
