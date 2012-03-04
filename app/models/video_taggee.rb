# == Schema Information
#
# Table name: video_taggees
#
#  id           :integer(4)      not null, primary key
#  contact_info :string(255)     not null
#  fb_id        :integer(4)
#  video_id     :string(255)     not null
#  created_at   :datetime
#

class VideoTaggee < ActiveRecord::Base
    belongs_to :video
    attr_accessor :should_destroy

    def edit
        @taggee = VideoTaggee.find(params[:id])
    end

    def img_path
        tmp = File.join(Video.directory_for_img(video_id), "faces","#{ id.to_s}.tif")
    end
 
    def self.find_all_video_ids_by_user_id(user_fbid)
      VideoTaggee.find_all_by_fb_id(user_fbid, :select => "video_id").map(&:video_id).uniq
    end
end
