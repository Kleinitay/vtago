class CommentsController < ApplicationController

=begin
  def create
    unless !signed_in? || !params[:comment]
      more_params = {:user_id => current_user.id }
# if someone changes it for using - Video.uri needs to receive fb_id and not id!!!!
      @ref = Video.uri(params[:comment][:video_id].to_i)
      @comment = Comment.new(params[:comment].merge(more_params))
      if @comment.save
        @done = true
      else
        @done = false
      end
      render "comment_published"
    else
      redirect_to ref
    end
  end
=end
end