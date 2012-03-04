module FacebookHelper

FACEBOOK_URL = "http://facebook.com"

  def fb_oauth
    @oauth ||= Koala::Facebook::OAuth.new(FB_APP_ID, FB_APP_SECRET, FB_SITE_URL)
  end

  def fb_graph
    @graph ||= Koala::Facebook::API.new(fb_access_token)
  end

  def fb_access_token(token = nil)
    @fb_access_token ||= if session['fb_access_token']
      session['fb_access_token']
    elsif fb_signed_request && fb_signed_request['oauth_token']
      session['fb_access_token'] = fb_signed_request['oauth_token']
    elsif cookies["fbsr_#{FB_APP_ID}"]
      session['fb_access_token'] = fb_oauth.get_user_info_from_cookie(cookies)['access_token']
    else
      session['fb_access_token'] = fb_oauth.get_app_access_token
    end
  end

  def fb_signed_request
    if !@fb_signed_request && params['signed_request']
      @fb_signed_request = session['fb_signed_request'] = fb_oauth.parse_signed_request(params['signed_request'])
    elsif session['fb_signed_request']
      @fb_signed_request ||= session['fb_signed_request']
    elsif @fb_signed_request
      @fb_signed_request
    else
      Rails.logger.debug "Could not set fb_signed_request!"
      Rails.logger.debug "session => #{session.inspect}"
      nil
    end
  end
  
  def fb_logout_url
     "https://www.facebook.com/logout.php?next=#{url_after_destroy}&access_token=#{fb_access_token}"
  end

  def post_vtag(new_video, friends_ids_arr, video_id, video_title)
    if friends_ids_arr.any?
      users_message_state = new_video ? "has Vtagged a new video" : "has updated a VtagO"
      post_on_users(users_message_state, video_id, video_title)
      post_on_friends(friends_ids_arr, video_id, video_title)
    end
  end

  def post_on_users(message_part, video_id, video_title)
    fb_graph.put_wall_post("",
                            {
	                            "name" => "VtagO - #{video_title}",
	                            "link" => "http://www.vtago.com/video/#{video_id}",
	                            "caption" => "#{fb_graph.get_object("me")["name"]} #{message_part}",
	                          },
	                          "#{current_user.fb_id}"
	                         )
  end

  def post_on_friends(friends_ids_arr, video_id, video_title)
    fb_graph.put_wall_post("",
                            {
	                            "name" => "VtagO - #{video_title}",
	                            "link" => "http://www.vtago.com/video/#{video_id}",
	                            "caption" => "#{fb_graph.get_object("me")["name"]} has Vtagged you"
	                          },
	                          "#{friends_ids_arr.join(",")}"
	                         )
  end
end
