module FacebookHelper
FACEBOOK_URL = "http://facebook.com"

  def fb_oauth
    @oauth ||= Koala::Facebook::OAuth.new(Facebook::APP_ID, Facebook::SECRET, Facebook::SITE_URL)
  end

  def post_vtag(fb_graph, new_video, taggees, video_fb_id, video_title, current_user)
    if taggees.any?
      logger.info "---Posting vtags to FB"
      users_message_state = new_video ? "has Vtagged a new VtagO" : "has updated a VtagO"
      post_on_users(fb_graph, users_message_state, video_fb_id, video_title, current_user)
      post_on_friends(fb_graph, taggees, video_fb_id, video_title)
    end
  end

  def post_on_users(fb_graph, message_part, video_fb_id, video_title, current_user)
    fb_graph.put_wall_post("",
                            {
	                            "name" => "VtagO - #{video_title}",
                              "link" => "#{Urls['site_url']}/auth/facebook?video_ref=#{Video.uri(video_fb_id, video_title)}&source=fb_user_post",
	                            "caption" => "#{fb_graph.get_object("me")["name"]} #{message_part}",
	                            "picture" => "#{Urls['site_url'] if Rails.env == "development"}#{Video.thumbnail(video_fb_id)}" 
	                          },
	                          "#{current_user.fb_id}"
	                         )
  end

  def post_on_friends(fb_graph, taggees, video_fb_id, video_title)
    taggees.each do |taggee|
      #logger.info "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ thumbnail url: #{taggee.thumbnail.url}"
      fb_graph.put_wall_post("",
                              {
  	                            "name" => "VtagO - #{video_title}",
                                "link" => "#{Urls['site_url']}/auth/facebook?video_ref=#{Video.uri(video_fb_id, video_title)}&default_cut=#{taggee.contact_info}&source=fb_tagged_post",
  	                            "caption" => "#{taggee.contact_info} got Vtagged by #{fb_graph.get_object("me")["name"]}",
	                              "picture" => "#{Urls['site_url'] if Rails.env == "development"}#{taggee.thumbnail.url}"
  	                          },
  	                          taggee.fb_id.to_s
  	                         )
    end
  end
end