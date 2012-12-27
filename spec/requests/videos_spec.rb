require 'spec_helper'
describe "Video" do

  before :all do
    @user = User.new
    @user.fb_id = 100003675844884
    @user.email = "klein.itay@gmail.com"
    @user.nick = "itikos kleinos"
    @user.remember_token = "2e86d8741b10f905f3c4a9257a4fc3cea4f6a0f8"
    @user.status = 2
    @user.fb_token = "AAABqZBYBHsSMBAHe72PfGf1JSJw6B0ZAbUjC0ndWNJR6OQ9ZBguUKvtRhtybEZCwySSMJ6AXfamlS2YTTu85LQrcMwUj3lBTMRFfCNp9wgZDZD"
    @user.password = "bibli"
    @user.save!
  end

  after :all do
    User.delete(@user)
  end

  before :each do
    @video = @user.videos.build
    @video.title = "stam"
    @video.duration = 0
    @video.category = 1
    @video.status_id = 1
    @video.save!
  end

  describe "#new" do
    it "Create a new video" do
      @video.should be_an_instance_of Video
    end
  end

 describe "title" do
   it "Has a title" do
     @video.title.should eql "stam"
   end
 end
 
 describe "user_name" do
   it "Has a user with a name" do
     User.find(@video.user_id).nick.should eql "itikos kleinos"
   end
 end
 
 describe "URI" do
   it "Has a valid uri" do
     @video.uri.should eql "/video/#{@video.id}-stam"
   end
 end

 describe "fb_URI" do
   it "Has a valid facebook uri" do
     @video.fb_uri.should eql "/fb/video/#{@video.id}"
   end
 end
 
 describe "Analyze video" do   
  before :each do
    @short = FactoryGirl.create(:video_short, user_id: @user.id)
  end
  context "wmv" do
    xit "should analyze wmv video" do
      @short.detect_face_and_timestamps "#{Rails.root}/TestVideos/shortest.wmv"
      (@short.video_taggees.length > 0 && File.exist?(@short.video_thumbnail.url)).should be_true
    end
  end
 end

  describe "Get width/height" do
    it "Detects width and height" do
      @short = FactoryGirl.create(:video_short, user_id: @user.id)
      info = @short.get_video_info @short.video_file.current_path
      widthight = @short.get_width_height info
      widthight[0].should eql 640 
      widthight[1].should eql 480
    end
  end

  describe "get_sidebar_data" do
    before :each do
      @itay = FactoryGirl.create(:user_itay)
      @eli = FactoryGirl.create(:user_eli)
      @eyal = FactoryGirl.create(:user_eyal)
      @v1 = FactoryGirl.create(:empty_video, user_id: @user.id, title: "1", views_count: 1000) do |v|
        v.video_taggees.create(contact_info: @eyal.nick, fb_id: @eyal.fb_id)
        v.video_taggees.create(contact_info: @itay.nick, fb_id: @itay.fb_id)
        v.video_taggees.create(contact_info: @eli.nick, fb_id: @eli.fb_id)
      end

      @v2 = FactoryGirl.create(:empty_video, user_id: @user.id, title: "2", views_count: 2000) do |v|
        v.video_taggees.create(contact_info: @eyal.nick, fb_id: @eyal.fb_id)
        v.video_taggees.create(contact_info: @itay.nick, fb_id: @itay.fb_id)
        v.video_taggees.create(contact_info: @eli.nick, fb_id: @eli.fb_id)
      end

      @v3 = FactoryGirl.create(:empty_video, user_id: @user.id, title: "3", views_count: 1500) do |v|
        v.video_taggees.create(contact_info: @eyal.nick, fb_id: @eyal.fb_id)
        v.video_taggees.create(contact_info: @itay.nick, fb_id: @itay.fb_id)
        v.video_taggees.create(contact_info: @eli.nick, fb_id: @eli.fb_id)
      end
      @v1.analyze!
      @v1.analyzed!
      @v1.done!
      sleep 1
      @v2.analyze!
      @v2.analyzed!
      @v2.done!
      sleep 1
      @v3.analyze!
      @v3.analyzed!
      @v3.done!


    end

    it "Gets videos by latest" do
      @sidebar_videos = Video.get_videos_by_sort(1, "latest", false, 3)
      #puts  "------" + @sidebar_videos.to_s
      @sidebar_videos.size.should eql 3
      @sidebar_videos[0].title.should eql "3" 
      @sidebar_videos[1].title.should eql "2"
      @sidebar_videos[2].title.should eql "1"

    end
    it "Gets videos by most popular" do
      @sidebar_videos = Video.get_videos_by_sort(1, "most popular", false, 3)
      #puts  "------" + @sidebar_videos.to_s
      @sidebar_videos.size.should eql 3
      @sidebar_videos[0].title.should eql "2" 
      @sidebar_videos[1].title.should eql "3"
      @sidebar_videos[2].title.should eql "1"
    end

    it "Finds friends on vtago" do
       friends_mapped = [{"value" => @eyal.nick, "id" => @eyal.fb_id},
                        {"value" => @eli.nick, "id" => @eli.fb_id},
                        {"value" => "shloopi", "id" => 123}]
      friends = User.find_friends_on_vtago friends_mapped
      puts "------" + friends.to_s
      friends.size.should eql 2
    end

    it "Gets user friends in_video" do
       friends_mapped = [{"value" => @eyal.nick, "id" => @eyal.fb_id},
                        {"value" => @eli.nick, "id" => @eli.fb_id},
                        {"value" => "shloopi", "id" => "shmoopi"}]
      friends = @v1.find_friends_in_video friends_mapped
      #puts "------" + friends.to_s
      friends.size.should eql 2
    end
  end
#full procedure
  describe "Full process" do
    it "Runs the full process from s3" do
      @video = FactoryGirl.create(:empty_video, user_id: @user.id)
      @video.filename = "shortest.mp4"
      @video.detect_and_convert false
      @video.video_taggees.length.should eql 1
      File.exist?(@short.video_thumbnail.url).should be_true
      File.exist?(@short.video_file.url).should be_true
    end
  end
#create vtags
#write player json
  describe "Write Json file" do
    it "Should write correct json with united cuts" do
      @video = FactoryGirl.create(:empty_video, user_id: @user.id)
      tag1 = @video.video_taggees.build
      tag1.contact_info = "1"
      tag1.save!
      tag2 = @video.video_taggees.build
      tag2.contact_info = "2"
      tag2.save!
      tag3 = @video.video_taggees.build
      tag3.contact_info = "1"
      tag3.save!
 
      for i in 0..5 do
        seg = tag1.time_segments.build
        seg.begin = 4*i * 1000
        seg.end = 4*i + 3 * 1000

        seg.save!
      end

      seg2 = tag1.time_segments.build
      seg2.begin = 4 + 1 * 1000
      seg2.end = 4 + 2 * 1000
      seg2.save!

      seg3 = tag1.time_segments.build
      seg3.begin = 100 * 1000
      seg3.end = 100 * 1000
      seg3.save!

      seg4 = tag3.time_segments.build
      seg4.begin = 50 * 1000
      seg4.end = 60 * 1000
      seg4.save!

      seg5 = tag2.time_segments.build
      seg5.begin = 50 * 1000
      seg5.end = 60 * 1000
      seg5.save!
     
      res = @video.to_player_json("1")
      res[:cuts].length.should eql 2
      res[:cuts][0][:segments].length.should eql 6
      res[:cuts][1][:segments].length.should eql 1
    end
  end



end  

 
 
