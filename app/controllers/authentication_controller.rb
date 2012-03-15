class AuthenticationController < ApplicationController
  def canvas
    redirect_to "/auth/facebook?signed_request=#{request.params['signed_request']}&state=canvas"
  end

  def create
    auth = request.env["omniauth.auth"]

    session['fb_uid'] = auth['uid']
    session['fb_access_token'] = auth['credentials']['token']

    if user = User.find_by_fb_id(auth['uid'])
      flash[:notice] = "Signed in successfully."  
    else  
      user = subscribe_new_fb_user(auth['extra']['raw_info'])
      flash[:notice] = "Authentication successful."  
    end 
    sign_in(user)
    redirect_to params[:state] == 'canvas' ? fb_video_list_path : '/video/latest'
  end

  def subscribe_new_fb_user(profile)
    user = User.new(:status => 2, 
                    :nick   => profile["name"], 
                    :email  => profile['email'], 
                    :fb_id  => profile["id"],
                    :password => SecureRandom.hex(10))

    user.remote_profile_pic_url = fb_graph.get_picture("me")
    user.save!
    user
  end

  def destroy
    raise 'TODO: Implement'
  end
end
