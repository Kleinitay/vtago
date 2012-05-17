class AuthenticationController < ApplicationController
  def canvas
    redirect_to "/auth/facebook?signed_request=#{request.params['signed_request']}&state=canvas"
  end

  def create
    auth = request.env["omniauth.auth"]
    if user = User.find_by_fb_id(auth['uid'])
      unless user.fb_token then user.update_attributes(:fb_token => auth['credentials']['token']) end
      flash[:notice] = "Signed in successfully."  
    else  
      user = subscribe_new_fb_user(auth['extra']['raw_info'], auth['credentials']['token'])
      flash[:notice] = "Authentication successful."  
    end 
    sign_in(user)
    if video_ref  = env["omniauth.params"]["video_ref"]
      default_cut = env["omniauth.params"]["default_cut"] || ""
      source      = env["omniauth.params"]["source"]
      redirect_to "#{video_ref}?default_cut=#{default_cut}&source=#{source}"
    else
      redirect_to params[:state] == 'canvas' ? fb_video_list_path : '/video/latest'
    end
  end

  def subscribe_new_fb_user(profile, access_token)
    user = User.new(:status => 2, 
                    :nick     => profile["name"], 
                    :email    => profile['email'], 
                    :fb_id    => profile["id"],
                    :fb_token => access_token,
                    :password => SecureRandom.hex(10))
    logger.info "-----------sending registration email"
    UserMailer.registration_confirmation(user).deliver
    user.remote_profile_pic_url = user.fb_graph.get_picture("me")
    user.save!
    user.save_fb_videos
    user
  end

  def destroy
    # Sadly OmniAuth doesn't want to parse the signed request for us 
    logger.info "--------------in the destroy user-------------------"
    oauth = Koala::Facebook::OAuth.new(Facebook::APP_ID, Facebook::SECRET, Facebook::SITE_URL)
    rc = oauth.parse_signed_request(params['signed_request'])
    user = User.find_by_fb_id(rc['user_id'].to_i)
    raise "Error removing user, not found: #{rc['user_id']}" unless user
    #user.update_attributes(:fb_token => nil)
      logger.info "-----destroying user"
    user.destroy
    logger.info "User #{user} removed facebook permissions"
  end
end
