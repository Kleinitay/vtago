# == Schema Information
#
# Table name: video_taggees
#
#  id           :integer(4)      not null, primary key
#  contact_info :string(255)     not null
#  fb_id        :integer(8)
#  video_id     :string(255)     not null
#  created_at   :datetime
#  updated_at   :datetime
#  taggee_face  :string(255)
#  thumbnail    :string(255)
#

class VideoTaggee < ActiveRecord::Base
    belongs_to :video
    has_many :time_segments, :foreign_key => 'taggee_id'
    accepts_nested_attributes_for :time_segments,
                                :allow_destroy => true


    attr_accessor :should_destroy, :face_guess_nick

    mount_uploader :taggee_face, TaggeeFaceUploader
    mount_uploader :thumbnail, ThumbnailUploader

    validate :contact_info_present

    def contact_info_present
      errors[:contact_info] = 'Cannot be blank' if contact_info.blank? and !taggee_face?
    end

    def edit
        @taggee = VideoTaggee.find(params[:id])
    end

    def img_path
      taggee_face? ? taggee_face : '/images/avatar.png'
    end

    def self.img_dir(taggee_id)
      if taggee = VideoTaggee.find_by_id(taggee_id)
        File.join(Rails.root, "public", Video.directory_for_img(taggee.video_id), "faces")
      else
        nil
      end
    end

    def self.thumb_dir(taggee_id)
      if taggee = VideoTaggee.find_by_id(taggee_id)
        File.join(Rails.root, "public", Video.directory_for_img(taggee.video_id), "thumbs")
      else
        nil
      end
    end

 
    def self.img_dir_for_s3(taggee_id)
      if taggee = VideoTaggee.find_by_id(taggee_id)
        File.join("faces", "#{taggee.video_id}_faces")
      else
        nil
      end
    end

    def self.thumb_dir_for_s3(taggee_id)
      if taggee = VideoTaggee.find_by_id(taggee_id)
        File.join("faces", "#{taggee.video_id}_thumbs")
      else
        nil
      end
    end

    def self.find_all_video_ids_by_user_id(user_fb_id)
      #VideoTaggee.find_all_by_fb_id(user_fb_id, :select => "video_id").map(&:video_id).uniq
      VideoTaggee.find_by_sql("select video_id from videos, video_taggees where video_taggees.video_id = videos.id and video_taggees.fb_id = #{user_fb_id} and videos.status_id != #{HIDDEN_VIDEO} group by videos.id").map(&:video_id)
    end

    def to_s
      str = "[%d] %s" % [video.id, contact_info]
      str += "(#{fb_id})" if fb_id
      str
    end

    def init_empty_taggee
     vid = Video.find(video_id)
     segment = self.time_segments.build
     segment.begin = 0
     segment.end = vid.duration * 1000
     segment.save
    end

    def use_face_com_for_name(face_com_client)
      img_url = Rails.env.production? ? taggee_face.url : "https://fbcdn-sphotos-a.akamaihd.net/hphotos-ak-ash4/427673_10150548336783645_181739168_n.jpg" 
#"https://fbcdn-sphotos-a.akamaihd.net/hphotos-ak-ash3/599961_10150937022283645_2128737996_n.jpg" 
        begin 
        fb_user = face_com_client.facebook_credentials[:fb_user]
        oauth_token = face_com_client.facebook_credentials[:oauth_token]
        api_call = "http://api.face.com/faces/recognize.json?" + 
        "api_key=#{FaceApi::FACE_API_KEY}&api_secret=#{FaceApi::FACE_API_SECRET}" + 
        "&urls=#{img_url}" + 
        "&uids=friends@facebook.com&namespace=facebook.com&detector=Aggressive&attributes=all" + 
        "&user_auth=fb_user:#{fb_user},fb_oauth_token:#{oauth_token}&"
        puts api_call
        res = RestClient.get("#{api_call}")
        result = JSON.parse(res)
        puts result
        raise "Error calling face api" if result.nil?
        raise result["photos"][0]["error_message"] if  result["photos"][0]["error_message"]
        raise "Missing tags part" unless result["photos"][0]["tags"]
        if  result["photos"][0]["tags"].length == 0 
          return "no face"
        end
        if result["photos"][0]["tags"][0]["uids"].length > 0
          return result["photos"][0]["tags"][0]["uids"][0]
        end
      rescue Exception => e
        logger.info e.message
        puts e.message
      end
      false
    end
end
