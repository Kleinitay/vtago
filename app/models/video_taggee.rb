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
#

class VideoTaggee < ActiveRecord::Base
    belongs_to :video
    attr_accessor :should_destroy

    mount_uploader :taggee_face, TaggeeFaceUploader

    def edit
        @taggee = VideoTaggee.find(params[:id])
    end

    def img_path
        tmp = File.join(Video.directory_for_img(video_id), "faces","#{ id.to_s}.tif")
    end

    def self.img_dir tagee_id
      tagee = VideoTaggee.find_by_id(tagee_id)
      tmp = File.join(Rails.root, "public", Video.directory_for_img(tagee.video_id), "faces")
    end
 
    def self.find_all_video_ids_by_user_id(user_fb_id)
      VideoTaggee.find_all_by_fb_id(user_fb_id, :select => "video_id").map(&:video_id).uniq
    end
end
