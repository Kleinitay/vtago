class VideoTaggeesController < ApplicationController


  def edit_segments
    @taggee = VideoTaggee.find(params[:id])
    @video = @taggee.video
  end

  def update
    @taggee = VideoTaggee.find(params[:id])
    if @taggee.update_attributes(params[:video_taggee]) 
      vid = Video.find(@taggee.video_id)
      redirect_to "/video/#{vid.id}/edit_tags"
    else
      redirect_to "/"
    end
  end
end
