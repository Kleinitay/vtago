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
    attr_accessor :should_destroy

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
      VideoTaggee.find_all_by_fb_id(user_fb_id, :select => "video_id").map(&:video_id).uniq
    end

    def to_s
      str = "[%d] %s" % [video.id, contact_info]
      str += "(#{fb_id})" if fb_id
      str
    end
end
