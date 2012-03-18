# == Schema Information
#
# Table name: video_taggees
#
#  id           :integer(4)      not null, primary key
#  contact_info :string(255)     not null
#  fb_id        :integer(4)
#  video_id     :string(255)     not null
#  created_at   :datetime
#  TaggeeFace   :string(255)
#

class VideoTaggee < ActiveRecord::Base
    belongs_to :video
    attr_accessor :should_destroy

    mount_uploader :TaggeeFace, TaggeeFaceUploader

    def edit
        @taggee = VideoTaggee.find(params[:id])
    end

    def img_path
        tmp = File.join(Video.directory_for_img(video_id), "faces","#{ id.to_s}.tif")
    end

    def self.img_path tagee_id
      tagee = VideoTaggee.find_by_id(tagee_id)
      tmp = File.join(Video.directory_for_img(tagee.video_id), "faces","#{ tagee_id.to_s}.tif")
    end
 
    def self.find_all_video_ids_by_user_id(user_fb_id)
      VideoTaggee.find_all_by_fb_id(user_fb_id, :select => "video_id").map(&:video_id).uniq
    end
end
