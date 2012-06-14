# == Schema Information
#
# Table name: videos
#
#  id              :integer(4)      not null, primary key
#  user_id         :integer(4)      not null
#  title           :string(255)
#  views_count     :integer(4)      default(0)
#  created_at      :datetime
#  updated_at      :datetime
#  duration        :integer(4)      not null
#  category        :integer(4)      not null
#  description     :string(255)
#  keywords        :string(255)
#  state           :string(255)
#  fb_id           :integer(8)
#  video_file      :string(255)
#  fb_src          :string(255)
#  analyzed        :boolean(1)      default(FALSE)
#  fb_thumb        :string(255)
#  fb_uploaded     :boolean(1)
#  filename        :text
#  video_thumbnail :string(255)
#

require "rexml/document"
require 'carrierwave/orm/activerecord'
require 'openssl'
require 'aws/s3'
#OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
include FacebookHelper

class Video < ActiveRecord::Base

  belongs_to :user
  has_many :comments, :dependent => :destroy
  has_many :video_taggees, :dependent => :destroy
  has_many :comments
  has_many :notifications

  accepts_nested_attributes_for :video_taggees,
                                :allow_destroy => true

  after_initialize :set_defaults

  validates_presence_of :title

  mount_uploader :video_file, VideoFileUploader
  mount_uploader :video_thumbnail, VideoThumbnailUploader
  # has_permalink :title, :as => :uri, :update => true
  # Check Why doesn't work??

  # Acts as State Machine
  # http://elitists.textdriven.com/svn/plugins/acts_as_state_machine
  acts_as_state_machine :initial => :pending
  state :analyzing
  state :pending
  state :untagged
  state :tagged 
  state :ready 
  state :error

  event :failed do
    transitions :from => :pending, :to => :error
    transitions :from => :untagged, :to => :error
    transitions :from => :tagged, :to => :error
    transitions :from => :analyzing, :to => :error
  end

  event :analyze do
    transitions :from => :pending, :to => :analyzing
    transitions :from => :analyzing, :to => :analyzing
  end

  event :analyzed do
    transitions :from => :analyzing, :to => :untagged
  end

  event :done do
    transitions :from => :untagged, :to => :ready
    transitions :from => :tagged, :to => :ready
  end

  event :tagged do
    transitions :from => :untagged, :to => :tagged
  end


#--------------------- Global params --------------------------
  IMG_VIDEO_PATH = "/videos/"
  DEFAULT_IMG_PATH = "#{IMG_VIDEO_PATH}default_img/"
  FULL_VIDEO_PATH = "#{Rails.root.to_s}/public/videos/"
  CATEGORIES = CommonData[:video_categories]
  MAIN_LIST_LIMIT = 10

  FACE_RESULTS = "faces.xml"
  FACES_DIR = "faces"
  MOVIE_FACE_RECOGNITION_EXEC_PATH = "#{Rails.root.to_s}/MovieFaceDetector/MovieFaceRecognition"
  HAAR_CASCADES_PATH = "#{Rails.root.to_s}/MovieFaceDetector/haarcascades/haarcascade_frontalface_alt_tree.xml"
  DEFAULT_WIDTH = 629
  DEFAULT_HEIGHT = 353


#------------------------------------------------------ Instance methods -------------------------------------------------------
  def set_defaults
    self.category ||= 1
    self.keywords ||= ''

  end

  def add_new_video(user_id, title)
    Video.create(:user_id => user_id, :title => title)
  end

  def title
    read_attribute(:title).force_encoding 'UTF-8'
  end

  def uri
    "/video/#{fb_id}#{title.nil? || title.empty? ? "" : "-" + PermalinkFu.escape(title)}"
  end

  def fb_uri
    "/fb/video/#{fb_id}"
  end

  def category_uri()
    "/video/#{category_tag}"
  end

  def category_tag
    CATEGORIES[category]
  end

  def category_title
    category_tag.titleize
  end

  # Moozly: path for saving temp origion uploaded video
  def path_for_origin
    string_id = (id.to_s).rjust(9, "0")
    "#{IMG_VIDEO_PATH}#{string_id[0..2]}/#{string_id[3..5]}/#{string_id[6..8]}/#{id}"
  end

  def thumb_path
    #File.join(Video.directory_for_img(id), "thumbnail.jpg")
    self.fb_thumb
  end

  def thumb_path_small
    File.join(TEMP_DIR_FULL_PATH, "tn_#{id}_small.jpg")
#    File.join(Video.directory_for_img(id), "thumbnail_small.jpg")
  end

  def thumb_path_big
    File.join(TEMP_DIR_FULL_PATH, "tn_#{id}.jpg")

#    File.join(Video.directory_for_img(id), "thumbnail_big.jpg")
  end

# Moozly: add file exists check for remote fb server
  def thumb_src(canvas = false)
    self.fb_thumb || "/images/pending_video#{'_fb' if canvas}.png"
    #FileTest.exists?("#{Rails.root.to_s}/public/#{thumb}") ? thumb : "#{DEFAULT_IMG_PATH}thumbnail.jpg"
  end

  def thumb_small_src # unused right now!!
    self.fb_thumb
                      #thumb = thumb_path_small
                      #FileTest.exists?("#{Rails.root.to_s}/public/#{thumb}") ? thumb : "#{DEFAULT_IMG_PATH}thumbnail_small.jpg"
  end

  def self.thumb_dir_for_s3(vid_id)
    begin
    vid = Video.find(vid_id)
      "videos_thumbs/vid_#{vid_id}"
    rescue Exception => e 
      logger.info e.to_s
      ""
    end

  end

  def hide
    self.hidden = true
    self.save
  end
  # run algorithm process
  def detect_and_convert(canvas)
    begin
      analyze!
      time_start = Time.now
      logger.info "Fetching from facebook/s3 for the detector"
      video_local_path = File.join(TEMP_DIR_FULL_PATH, "#{id.to_s}#{File.extname(self.s3_file_name)}")
      system("wget \'#{ !self.fb_id ? self.s3_file_name : self.fb_src}\' -O #{video_local_path} --no-check-certificate")
      logger.info "---- fetching took #{Time.now - time_start} - now Getting video info"
      video_info = get_video_info video_local_path
      unless video_info["Duration"].nil?
        dur = parse_duration_string video_info["Duration"]
        self.duration = dur
      end
      logger.info "---- converting to FLV"
      unless convert_to_flv video_local_path, get_flv_file_name, video_info
        return false
      end
      #perform the face detection
      logger.info "---- fetching + conversion took #{Time.now - time_start} - now Running detection"
     # file_to_work = is_video_rotated(video_info) || (get_width_height(video_info)[0] > DEFAULT_WIDTH || get_width_height(video_info)[1] > DEFAULT_HEIGHT) ? get_flv_file_name : video_local_path
      file_to_work = get_flv_file_name
      detect_face_and_timestamps file_to_work 
      update_attribute(:analyzed, true)
      time_end = Time.now
      logger.info "=======Detection process took #{time_end - time_start} seconds"
      # 	 check_if_analyze_or_upload_is_done("analyze",canvas)
      logger.info "----adding notification"
      self.notifications.create(:type_id => 1, :message => "Hey, your new video #{title} is ready to get Vtagged!", :user_id => self.user_id)
      analyzed!
      logger.info "------- uploading file to s3"
      self.video_file = File.open(get_flv_file_name)
      save!
      #cleanup
      delete_from_s3_if_possible
      #deleting local video File
      logger.info "---The local file " + video_local_path.to_s + " exists " + File.exist?(video_local_path).to_s + " uploaded=" + self.fb_uploaded.to_s
      to_delete = File.exist?(video_local_path)
      if Rails.env.development?
        Video.connection.clear_query_cache
        vid = Video.find(self.id)
        to_delete = File.exist?(video_local_path) && vid.analyzed
      end
      if to_delete
        logger.info "deleting local video file"
        File.delete video_local_path
      end
      if File.exist?(get_flv_file_name)
        File.delete get_flv_file_name
      end
    rescue Exception => e
      logger.info "!!!!!!!!!!!!!!!  got an error in detect_and_convert!!!!!!!!!!!!!!!! !" + e.message + "  " + e.backtrace.join("\n")
      #todo: clear everything here
      failed!
    end
  end

  def delete_from_s3_if_possible
    Video.connection.clear_query_cache
    vid = Video.find(self.id)
    if (vid.analyzed && vid.fb_uploaded)
      #establish s3 connection
      AWS::S3::Base.establish_connection!(:access_key_id => AWS_KEY, :secret_access_key => AWS_SECRET)
      logger.info "the file to delete from s3 is: " + self.s3_file_name + "the file is: " + File.basename(self.s3_file_name)
      AWS::S3::S3Object.delete "test/#{File.basename(self.s3_file_name)}", VIDEO_BUCKET
    end
  end

  def upload_video_to_fb(retries, timeout, canvas, current_user)
    #downloading from s3
    begin
      raise 'video already uploaded' if fb_id
      logger.info "fetching from s3 for the uploader"
      time_start = Time.now
      video_local_path = File.join(TEMP_DIR_FULL_PATH, "#{id.to_s}_u#{File.extname(self.s3_file_name)}")
      system("wget \'#{self.s3_file_name}\' -O #{video_local_path}")
      logger.info "uploading:  " + video_local_path 
      # video_info = get_video_info  video_local_path
      # if convert_to_flv video_local_path, video_info
      #   File.delete video_local_path
      #   video_local_path = get_flv_file_name
      # end
      post_args = private ? 
        {:title => self.title, :description => self.description, :privacy => '{"value": "CUSTOM", "friends": "SELF"}'} :
        {:title => self.title, :description => self.description }
        
      result = fb_graph.put_video(video_local_path, post_args)
      return false if !result
      logger.info "Trying to get object for the first time"
      fb_video = fb_graph.get_object(result["id"])
      i = 1
      while !fb_video && i <= retries
        logger.info "Retrying get object for the " + i.to_s
        sleep timeout * i
        fb_video = fb_graph.get_object(result["id"])
        i = i + 1
      end
      if fb_video
        time_end = Time.now
        logger.info "Got it!!! upadating fb params, src:  #{fb_video["src"]}, picture: #{fb_video["picture"]}"
        logger.info "=======uploading to FB took #{time_end - time_start} seconds"
        update_attributes(:fb_uploaded => true, :fb_id => fb_video["id"], :fb_src => fb_video["source"], :fb_thumb => fb_video["picture"])
        check_if_analyze_or_upload_is_done("upload", canvas)
      end
      if current_state == "tagged"
        post_vtags_to_fb current_user
        done!
      end

      #deleting local video File
      to_delete = File.exist?(video_local_path)
      if Rails.env.development?
        Video.connection.clear_query_cache
        vid = Video.find(self.id)
        to_delete = File.exist?(video_local_path) && vid.analyzed
      end
      logger.info "---The local file " + video_local_path.to_s + " exists " + File.exist?(video_local_path).to_s + " analyzed=" + self.analyzed.to_s
      if to_delete
        logger.info "deleting local video file"
        File.delete video_local_path
      end
      logger.info "------ deleting flv file"
      if File.exist?(get_flv_file_name)
        File.delete(get_flv_file_name)
      end
      delete_from_s3_if_possible
      logger.info "----State is " + current_state
    rescue Exception => e
      logger.info "!!!!!!!!   upload to FB failed with exception " + e.message
      failed!
    end
  end

  def current_state
    Video.connection.clear_query_cache
    v = Video.find(id)
    v.state
  end


  def check_if_analyze_or_upload_is_done(operation, canvas)
    Video.connection.clear_query_cache
    video = Video.find(self.id)
    if (operation == "upload" and !video.analyzed && video.state != "error") ||
        (operation == "analyze" and !video.fb_uploaded && video.state != "error")
      wait_for_upload_and_analyze(canvas)
    end
  end

  def wait_for_upload_and_analyze(canvas)
    video = self
    i = 0
    while (video.nil? || !video.analyzed || !video.fb_uploaded) && i < 200
      logger.info "still busywaiting"
      logger.info "video.analyzed=" + video.analyzed.to_s
      logger.info "video.fb_uploaded=" + video.fb_uploaded.to_s
      sleep(10)
      Video.connection.clear_query_cache
      video = Video.find(self.id)
      i = i + 1
    end
    video.fb_id
  end

  def post_vtags_to_fb(current_user)
    taggees = video_taggees_uniq.map{|taggee| taggee unless (!taggee.fb_id || (taggee.fb_id == current_user.fb_id))}.compact
    post_vtag(current_user.fb_graph, true, taggees, fb_id, title.titleize, current_user) unless self.private
    taggee_fb_ids = taggees.map(&:fb_id)
    create_vtagged_notifications(taggee_fb_ids)
  end

  def create_vtagged_notifications(taggee_fb_ids)
    user_ids = User.all(:select => "id", :conditions => "fb_id in (#{taggee_fb_ids.join(',')})").map(&:id)
    message = "Hey, #{self.user.nick} just Vtagged you in the video '#{self.title}'"
    user_ids.each do |user_id|
      self.notifications.create(:type_id => 3, :message => message, :user_id => user_id)
    end
  end

  def video_taggees_uniq
    VideoTaggee.find(:all, :select => "contact_info, fb_id, id, thumbnail, video_id", :group=>"contact_info", :conditions => ["video_id = #{self.id} and contact_info != ''"])
  end

  def parse_duration_string duration_str
    minstr = duration_str.slice(/[0-9]+mn/)
    unless minstr.nil?
      mins = minstr.slice(/[0-9]+/)
    end
    secstr = duration_str.slice(/[0-9]+s/)
    unless secstr.nil?
      secs = secstr.slice(/[0-9]+/)
    end
    mins.to_i*60+secs.to_i
  end

  def delete_video_files
    #return this when we start using s3
    #remove_video_file
    #File.delete File.join(Rails.root, "public", thumb_path)
    #File.delete File.join(Rails.root, "public", thumb_path_small)
  end

  def delete(fb_delete, graph=nil)
    delete_video_files
    if fb_delete
      fb = fb_destroy(graph)
    end
    self.destroy
    if fb_delete
      if fb
        "Video has been deleted from site and Facebook successfully."
      else
        "Video has been deleted from site successfully but there was a problem deleting it from Facebook."
      end
    else
      "Video has been deleted from site successfully."
    end
  end

  def fb_destroy(graph)
    graph.delete_object(self.fb_id)
  end

  def fb_graph
    user.fb_graph
  end

  # _____________________________________________ FLV/webm conversion functions _______________________

  def convert_to_flv (video_path, output_file,video_info)
    logger.info "---------------in the conversion"
    dims = get_width_height video_info
    cmd = convert_to_flv_command video_path, output_file, video_info, dims[0], dims[1]
    logger.info cmd 
    success = system(cmd + " > #{Rails.root}/log/convertion.log")
    logger.info "-------------after the conversion is done"
    unless success && $?.exitstatus == 0
      logger.info "---------why did i fail????????????????"
      self.failed!
    end
    true
  end


  def convert_to_mp4(video_path, video_info)
    logger.info "---------------in the conversion"
    dims = get_width_height video_info
    cmd = convert_to_h264_command video_path, video_info, video_info["Width"].gsub(/\s+/, '').to_i, video_info["Height"].gsub(/\s+/, '').to_i
    logger.info "after the conversion command"
    logger.info(cmd)
    success = system(cmd + " > #{Rails.root}/log/convertion.log")
    logger.info "-------------after the conversion is done"
=begin
    if dims[0] % 2 != 0
      dims[0] += 1
    end
    if dims[1] % 2 != 0
      dims[1] += 1
    end
    success = system(convert_to_webm_command video_info, dims[0], dims[1])
=end
    unless success && $?.exitstatus == 0
      logger.info "---------why did i fail????????????????"
      self.failed!
    end
    true
  end


  def get_adjusted_width_height video_info
    width = DEFAULT_WIDTH
    height = DEFAULT_HEIGHT
    unless video_info["Width"].nil? || video_info["Height"].nil?
      origWidth = video_info["Width"].gsub(/\s+/, '').to_i
      origHeight = video_info["Height"].gsub(/\s+/, '').to_i
      if origHeight / origWidth >= 353/629
        width = origWidth * height / origHeight
      else
        height = origHeight * width / origWidth
      end
    end
    [width, height]
  end

  def get_width_height video_info
    unless video_info["Width"].nil? || video_info["Height"].nil?
      [video_info["Width"].gsub(/\s+/, '').to_i, video_info["Height"].gsub(/\s+/, '').to_i]
    end
  end

  def set_new_filename
    #update_attribute(:source_file_name, "#{id}.flv")
    #debugger
    self.video_file = File.open(get_flv_file_name)
  end

  def s3_file_name
    "https://s3.amazonaws.com/#{Amazon::BUCKET}/test/#{filename}"
  end

  def get_flv_file_name
    #dirname = Video.full_directory(id)
    #File.join(dirname, "#{id}.flv")
    File.join(TEMP_DIR_FULL_PATH, "#{id}.flv")
  end

  def get_flv_file_name_for_uploader
     File.join(TEMP_DIR_FULL_PATH, "#{id}_u.flv")
  end

  def get_webm_file_name
    #dirname = Video.full_directory(id)
    #File.join(dirname, "#{id}.webm")

  end

  def get_h264_file_name
    dirname = Video.full_directory(id)
    File.join(TEMP_DIR_FULL_PATH, "#{id}.mp4")
  end

  def convert_to_flv_command(video_path, output_file, video_info, width, height)
    File.open(output_file, 'w')
    command = <<-end_command
    ffmpeg -i #{ video_path } #{get_video_rotation_cmd video_info['Rotation']} -ar 22050 -ab 32 -acodec libmp3lame -s #{width}x#{height} -vcodec flv -r 25 -qscale 8 -f flv -y #{ output_file }
    end_command
    command.gsub!(/\s+/, " ")
    puts command
    command
  end


  def convert_to_webm_command(video_path, video_info, width, height)
    output_file = self.get_webm_file_name
    File.open(output_file, 'w')
    command = <<-end_command
    ffmpeg -i #{ video_path} #{get_video_rotation_cmd video_info['Rotation']} -c:v libvpx -ar 44100 -ab 96k -acodec libvorbis -s #{width}x#{height} -b 345k -y #{ output_file }
    end_command
    command.gsub!(/\s+/, " ")
    puts command
    command
  end

  def convert_to_h264_command (video_path, video_info, width, height)
    output_file = File.join(TEMP_DIR_FULL_PATH, "#{id.to_s}.mp4")
    File.open(output_file, 'w')
    command = <<-end_command
    ffmpeg -i #{ video_path } #{get_video_rotation_cmd video_info['Rotation']}  -acodec libmp3lame -ab 96k -vcodec libx264 -level 21 -refs 2 -b 345k -bt 345k -g 1
    -threads 0 -s #{width}x#{height} -y #{ output_file }
    end_command
    command.gsub!(/\s+/, " ")
    puts command
    command
  end

 def convert_to_h264_for_fb_command (video_path)
    output_file = self.get_h264_file_name
    File.open(output_file, 'w')
    command = <<-end_command
    ffmpeg -i #{ video_path } -acodec libmp3lame -ab 96k -vcodec libx264 -level 21 -refs 2 -b 345k -bt 345k -g 2 -threads 0 -y #{ output_file }
    end_command
    command.gsub!(/\s+/, " ")
    puts command
    command
  end




  def get_video_info (video_path)
    response =`mediainfo #{ video_path } --Output=XML 2>&1`
    if response == nil
      return
    end
    xml_hash = Hash.from_xml response
    xml_hash['Mediainfo']['File']['track'][1]
  end

  def get_video_rotation_cmd (degrees=nil)
    #mediainfo_path = File.join( Rails.root, "Mediainfo", "Mediainfo")
    #response =`#{mediai)fo_path} #{source.path} --output=json 2>&1`
    # response = response.gsub(/ /,'')
    if degrees.nil? || degrees == ""
      return ""
    elsif degrees[0, 2] == "18"
      return "-vf transpose=3"
    elsif degrees[0, 2] == "27"
      return "-vf transpose=1"
    elsif degrees[0, 2] == "90"
      return "-vf transpose=0"
    else
      return ""
    end
  end

  def is_video_rotated (video_info)
    return !video_info['Rotation'].nil? != "" && video_info['Rotation'] != "" 
  end

  # _____________________________________________ FLV conversion functions _______________________

  #------------------------------------------------------ Class methods -------------------------------------------------------
  def self.uri(fb_id, title=nil)
    unless title then title = Video.find_by_fb_id(fb_id, :select => 'title,category,keywords').title end
    "/video/#{fb_id}-#{PermalinkFu.escape(title)}"
  end

  def self.fb_uri(fb_id)
    "/fb/video/#{fb_id}"
  end

  def self.directory_for_img(video_id)
    string_id = (video_id.to_s).rjust(9, "0")
    File.join("#{IMG_VIDEO_PATH}#{string_id[0..2]}", "#{string_id[3..5]}", "#{string_id[6..8]}")
  end

  def self.full_directory(video_id)
    string_id = (video_id.to_s).rjust(9, "0")
    "#{FULL_VIDEO_PATH}#{string_id[0..2]}/#{string_id[3..5]}/#{string_id[6..8]}"
  end

#  def self.full_directory_for_url(video_id)
#    Video.full_directory(video_id).gsub("/","%2F")
#  end

  def self.thumbnail(fb_id)
    Video.find_by_fb_id(fb_id).video_thumbnail.url
  end

  def self.for_view(fb_id)
    video = Video.find_by_fb_id(fb_id)
  end

  def fb_src
    user = User.find(user_id)
    res = user.fb_graph.get_object(fb_id)
    res ? res["source"] : ""
  end

  # Moozly: the functions gets videos for showing in a list by sort order - latest or most popular  
  def self.get_videos_by_sort(page, order_by, canvas, limit = MAIN_LIST_LIMIT)
    sort = order_by == "latest" ? "updated_at" : "views_count"
    params = {:page => page,
              :per_page => limit,
              :conditions => {:fb_uploaded => true}
    }
    vs = Video.paginate(params).order("#{sort } desc")
    populate_videos_with_common_data(vs, canvas, true) if vs
  end

  # Moozly: the functions gets videos for showing in a list by the video category
  def self.get_videos_by_category(page, category_id, limit = MAIN_LIST_LIMIT)
    params = {:page => page,
              :per_page => limit,
              :conditions => {:fb_uploaded => true, :category => category_id}
    }
    vs = Video.paginate(params).order("created_at desc")
    populate_videos_with_common_data(vs, false, false) if vs
  end

  def self.get_videos_by_user(page, user_id, own_videos, canvas, limit = MAIN_LIST_LIMIT)
    params = {:page => page, :per_page => limit}
    params[:conditions] = {:fb_uploaded => true} unless own_videos
    vs = Video.where({:user_id => user_id}).paginate(params).order("created_at desc")
    populate_videos_with_common_data(vs, canvas, name = false) if vs
  end

  def self.find_all_by_vtagged_user(user_fb_id, canvas)
    vs_ids = VideoTaggee.find_all_video_ids_by_user_id(user_fb_id)
    @vs = vs_ids.any? ? self.where("id in (#{vs_ids.join(",")})") : []
    @vs.each do |v|
      user = v.user
      v[:user_id] = user.id
      v[:user_fb_id] = user.fb_id
      v[:user_nick] = user.nick
      v[:thumb] = v.thumb_src(canvas)
    end
  end

  def self.populate_videos_with_common_data(vs, canvas, name = false)
    vs.each do |v|
      user = v.user
      v[:user_id] = user.id
      v[:user_nick] = user.nick
      v[:thumb] = v.thumb_src(canvas)
      v[:analyzed_ref] = "/#{'fb/' if canvas}video/#{v.analyzed ? "#{v.id}/edit_tags" : "#{v.fb_id}/analyze"}"
      v[:button_title] = v.analyzed ? "Edit Tags" : "Vtag this video"
      v[:category_title] = v.category_title if name
    end
  end

# _____________________________________________ Face detection _______________________

  def detect_face_and_timestamps(filename)
    create_faces_directory
    cmd = detect_command filename
    logger.info cmd
    puts cmd
    success = system(cmd + " > #{Rails.root}/log/detection.log")
    if success && $?.exitstatus == 0
      parse_xml_add_tagees_and_timesegments(get_timestamps_xml_file_name)
      File.delete get_timestamps_xml_file_name
     logger.info "----- setting video_thumbnail to " + thumb_path_big
     self.video_thumbnail = File.open(thumb_path_big)
     File.delete(thumb_path_big) if File.exist?(thumb_path_big)
     File.delete(thumb_path_small) if File.exist?(thumb_path_small)
    else
      self.failed!
    end
  end

  def get_avi_file_name
    File.join(Video.full_directory(:id), "#{id.to_s}.avi")
  end

  def get_timestamps_xml_file_name
    File.join(temp_faces_directory, FACE_RESULTS)
  end

  def detect_command (filename)
    output_dir = temp_faces_directory
    #input_file = File.join(Video.full_directory(id),id.to_s)
    input_file = filename

    "#{MOVIE_FACE_RECOGNITION_EXEC_PATH} Dreamline #{input_file} #{output_dir} #{HAAR_CASCADES_PATH} #{thumb_path_big} #{thumb_path_small} "
  end

  def faces_directory
    File.join(Video.full_directory(id), FACES_DIR)
  end

  def temp_faces_directory
    File.join(TEMP_DIR_FULL_PATH, "#{id.to_s}_faces")
  end

  def create_faces_directory
    Dir.mkdir(temp_faces_directory)
    system("chmod -R 777 #{temp_faces_directory}")
  end

  def add_taggees
    VideoTaggee.new
  end

  def parse_xml_add_tagees_and_timesegments (filename)
    file = File.new(filename)
    doc = REXML::Document.new file
    doc.elements.each('//face') do |face|
      taggee = self.video_taggees.build
      taggee.contact_info = ""
      taggee.taggee_face = File.open(face.attributes["path"])
      taggee.thumbnail = File.open(face.attributes["thumb_path"])
      taggee.save
      logger.info "------ deleting: #{face.attributes["path"]} and #{face.attributes["thumb_path"]}"
      File.delete(face.attributes["path"])
      File.delete(face.attributes["thumb_path"])
      #File.delete(newFilename)
      face.elements.each("timesegment ") do |segment|
        newSeg = TimeSegment.new
        newSeg.begin = segment.attributes["start"].to_i
        newSeg.end = segment.attributes["end"].to_i
        newSeg.taggee_id = taggee.id
        newSeg.save
      end
    end
  end


# _____________________________________________ Face detection _______________________

#___________________________________________taggees handling______________________

  def to_player_json(default_face)
    resHash = {:name => self.title, :defaultCut => default_face}
    tags = VideoTaggee.find_all_by_video_id(id)
    cuts = []
    tags.each do |tag|
      unless tag.contact_info.empty?
        segs = TimeSegment.find_all_by_taggee_id(tag.id)
        times = []
        segs.each do |seg|
          times << [seg.begin / 1000 - 1, seg.end / 1000 + 2]
        end
        #times = screen_and_unite_segments times
        cuts << {:name => tag.contact_info, :segments => times}
      end
    end
    cuts = unite_cuts_with_same_name cuts
    cuts.each_index do |i|
        cuts[i][:segments] = screen_and_unite_segments(cuts[i][:segments])
        cuts[i][:segments] = screen_and_unite_segments(cuts[i][:segments])
    end
    resHash[:cuts] = cuts
    resHash
  end

  def unite_cuts_with_same_name(cuts)
    new_cuts = []
    cuts.each_with_index do |cut|
      unless cut[:name] == ""
        cuts.each do |cut2|
          if cuts.index(cut) < cuts.index(cut2) && cut[:name] == cut2[:name]
            cut[:segments].concat(cut2[:segments])
            cut2[:name] = ""
          end
        end
        new_cuts << cut
      end
    end
    new_cuts
  end

  def screen_and_unite_segments (segments)
    #screen
    segments.delete_if { |i| i[0] == i[1] }
    #unite
    segments.each_index do |i|
      unless !segments[i] || i >= segments.count - 1
        for j in i + 1..segments.count - 1
          if segments[j] && segments[i][1] >= segments[j][0]
            segments [i][1] = [segments[j][1], segments [i][1]].max
            segments[j] = nil
          end
        end
      end

    end
    segments.compact
  end

  def write_temp_player_file (default_face, file_path)
    toWrite = to_player_json default_face
    j = ActiveSupport::JSON
    File.open(file_path, 'w') { |f| f.write(j.encode(toWrite)) }
  end

  def player_file_path
    "/tmp/player_cuts" + self.id.to_s + ".json"
  end

  def player_file__full_path
    TEMP_DIR_FULL_PATH + "/" + "player_cuts" + self.id.to_s + ".json"
  end

  def self.number_of_pending_videos(current_user_id)
    Video.all(:conditions => ['state = ? and user_id = ?', 'analyzing', current_user_id.to_s]).count
  end

  def gen_player_file(default_cut)
    unless Dir.exist? (TEMP_DIR_FULL_PATH)
      Dir.mkdir(TEMP_DIR_FULL_PATH, 0777)
    end
    #nick = current_user ? current_user.nick : ""
    write_temp_player_file(default_cut, player_file__full_path)
    player_file_path
  end

  def update_time_to_now
    self.updated_at = Time.now
  end
end

