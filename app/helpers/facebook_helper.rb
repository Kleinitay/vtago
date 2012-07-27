module FacebookHelper
FACEBOOK_URL = "http://facebook.com"

  def fb_oauth
    @oauth ||= Koala::Facebook::OAuth.new(Facebook::APP_ID, Facebook::SECRET, Facebook::SITE_URL)
  end

  def post_vtag(fb_graph, new_video, taggees, video_id, video_title, current_user)
    if taggees.any?
      logger.info "---Posting vtags to FB"
      users_message_state = new_video ? "has tagged some friends in a new video using VtagO" : "has updated a video using VtagO"
     post_on_users(fb_graph, users_message_state, video_id, video_title, current_user)
     post_on_friends(fb_graph, taggees, video_id, video_title)
    # post_action_on_user(fb_graph, video_id, video_title, current_user)
    end
  end

  def post_on_users(fb_graph, message_part, video_id, video_title, current_user)
    fb_graph.put_wall_post("",
                            {
	                            "name" => "VtagO - #{video_title}",
                              "link" => "#{Urls['site_url']}/auth/facebook?video_ref=#{Video.uri(video_id, video_title)}&source=fb_user_post",
	                            "caption" => "#{fb_graph.get_object("me")["name"]} #{message_part}",
	                            "picture" => "#{Urls['site_url'] if Rails.env == "development"}#{Video.thumbnail(video_id)}"
	                          },
	                          "#{current_user.fb_id}"
	                         )
  end

  def post_on_friends(fb_graph, taggees, video_id, video_title)
    taggees.each do |taggee|
      #logger.info "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ thumbnail url: #{taggee.thumbnail.url}"
      fb_graph.put_wall_post("",
                              {
  	                            "name" => "VtagO - #{video_title}",
                                "link" => "#{Urls['site_url']}/auth/facebook?video_ref=#{Video.uri(video_id, video_title)}&default_cut=#{taggee.contact_info}&source=fb_tagged_post",
  	                            "caption" => "#{taggee.contact_info} was tagged in a video by #{fb_graph.get_object("me")["name"]} using VtagO",
	                              "picture" => "#{Urls['site_url'] if Rails.env == "development"}#{taggee.thumbnail.url || Video.thumbnail(video_id)}}"
  	                          },
  	                          taggee.fb_id.to_s
  	                         )
    end
  end

  def post_action_on_friends(fb_graph, video_id, video_title)
    fb_graph.put_connections("me", "vtagoappbeta:vtag",Video.uri(video_id, video_title))
  end

  def post_action_on_user(fb_graph, video_id, video_title, current_user)
    logger.info("-------------------videoURI = " + Video.uri(video_id, video_title))
    vid = Video.find(video_id)
    siteurl = Rails.env.production? ? Urls['site_url'] : "example.com"
    result = fb_graph.put_connections("me", "vtagoapp:vtago",
                             :object => "#{siteurl}/auth/facebook?video_ref=#{Video.uri(video_id, video_title)}&source=fb_user_post",
                             :other => "#{siteurl}#{Video.uri(video_id, video_title)}",
                             :tags => "665131761", :image => "#{Urls['site_url'] if Rails.env == "development"}#{vid.video_thumbnail.url}")
    logger.info "----------------result from action: " + result
  end
end