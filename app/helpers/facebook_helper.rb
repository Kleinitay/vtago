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
	                            "link" => "#{Urls['site_url']}/video/#{video_fb_id}",
	                            "caption" => "#{fb_graph.get_object("me")["name"]} #{message_part}"
	                            #"picture" => Video.thumbnail_url(video_fb_id)
	                          },
	                          "#{current_user.fb_id}"
	                         )
  end

  def post_on_friends(fb_graph, taggees, video_fb_id, video_title)
    logger.info "Posting on walls of #{taggees.map(&:contact_info)}"
    taggees.each do |taggee|
      fb_graph.put_wall_post("",
                              {
  	                            "name" => "VtagO - #{video_title}",
  	                            "link" => "#{Urls['site_url']}/video/#{video_fb_id}",
  	                            "caption" => "#{taggee.contact_info} got Vtagged by #{fb_graph.get_object("me")["name"]}",
  	                            "picture" => "#{Urls['site_url']}#{taggee.thumbnail.url}"
  	                          },
  	                          taggee.fb_id.to_s
  	                         )
    end
  end
  
  def post_on_test_friend(fb_graph, friends_ids_arr, video_fb_id, video_title)
    fb_graph.put_wall_post("",
                            {
	                            "name" => "VtagO - #{video_title}",
	                            "link" => "#{Urls['site_url']}/video/test_show",
	                            "caption" => "#{fb_graph.get_object("me")["name"]} has Vtagged you"
	                          },
	                          "#{friends_ids_arr.join(",")}"
	                         )
  end
end