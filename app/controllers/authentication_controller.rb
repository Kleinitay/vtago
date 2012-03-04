class AuthenticationController < ApplicationController
  def index
      @authetications = Authentication.all
  end

  #def create
  #    auth = request.env["omniauth.auth"] .to_yaml
  #    current_user.authentications.build(:provider => auth['provider'], :uid => auth['uid'])
  #    session['fb_uid'] = auth['uid']
  #    session['fb_access_token'] =
  #    redirect_to authentications_url
  #end

  def get_uid_and_access_token
      auth = request.env["omniauth.auth"]
      uid = auth['uid']
      token =  auth['credentials']['token']
      session['fb_uid'] = auth['uid']
      session['fb_access_token'] = auth['credentials']['token']
      parse_facebook_cookies
      redirect_to '/video/latest'
  end

  def parse_facebook_cookies
    unless signed_in?
      begin
        fb_id = session['fb_uid']
        if fb_id #Logged in with Facebook
          user = User.find_by_fb_id(fb_id)
          if user
            user.remote_profile_pic_url = fb_graph.get_picture("me")
            user.save
            sign_in(user)
          else
            subscribe_new_fb_user(fb_id) # new Facebook user
          end
        end
      rescue Exception=>e
        render :text => "Session Has gone away. Please refresh and login again."
        sign_out
      end
    end
  end

  def subscribe_new_fb_user(fb_id)
    profile = fb_graph.get_object("me")
    nick = profile["name"]
    email = profile["email"]
    fb_id = profile["id"]
    password = SecureRandom.hex(10)
    user = User.new(:status => 2, :nick => nick, :email => email, :fb_id => fb_id, :password => password)
    user.remote_profile_pic_url = fb_graph.get_picture("me")
    user.save
    sign_in(user)
  end

  def destroy
  end
end
