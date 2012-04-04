# == Schema Information
#
# Table name: videos
#
#  id          :integer(4)      not null, primary key
#  user_id     :integer(4)      not null
#  title       :string(255)
#  views_count :integer(4)      default(0)
#  created_at  :datetime
#  updated_at  :datetime
#  duration    :integer(4)      not null
#  category    :integer(4)      not null
#  description :string(255)
#  keywords    :string(255)
#  state       :string(255)
#  fb_id       :integer(8)
#  video_file  :string(255)
#  fb_src      :string(255)
#  analyzed    :boolean(1)      default(FALSE)
#  fb_thumb    :string(255)
#

require "rexml/document"
require 'carrierwave/orm/activerecord'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
include FacebookHelper

class Video < ActiveRecord::Base

  belongs_to :user
  has_many :comments, :dependent => :destroy
  has_many :video_taggees, :dependent => :destroy
  has_many :comments

  after_initialize :set_defaults

  validates_presence_of :title

  mount_uploader :video_file, VideoFileUploader

  # has_permalink :title, :as => :uri, :update => true
  # Check Why doesn't work??

  after_update :save_taggees
  # Acts as State Machine
  # http://elitists.textdriven.com/svn/plugins/acts_as_state_machine
  acts_as_state_machine :initial => :pending
  state :pending
  state :analysing
  state :analysed, :enter => :convert_to_flv
  state :converting
  state :converted, :enter => :set_new_filename
  state :error

  event :convert_to_flv do
    transitions :from => :pending, :to => :converting
    transitions :from => :analysed, :to => :converting
  end

  event :converted do
    transitions :from => :converting, :to => :converted
  end

  event :failed do
    transitions :from => :converting, :to => :error
  end

  event :analyse do
    transitions :from => :pending, :to => :analysing
  end

  event :analysed do
    transitions :from => :analysing, :to => :analysed
  end

  event :analyse do
    transitions :from => :converted, :to => :analysing
    transitions :from => :pending, :to => :analysing
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
    self.category ||= 0
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
    File.join(Video.directory_for_img(id), "thumbnail_small.jpg")
  end

  def thumb_path_big
     File.join(Video.directory_for_img(id), "thumbnail_big.jpg")
  end

# Moozly: add file exists check for remote fb server
  def thumb_src
    self.fb_thumb
    #FileTest.exists?("#{Rails.root.to_s}/public/#{thumb}") ? thumb : "#{DEFAULT_IMG_PATH}thumbnail.jpg"
  end

  def thumb_small_src
    thumb = thumb_path_small
    FileTest.exists?("#{Rails.root.to_s}/public/#{thumb}") ? thumb : "#{DEFAULT_IMG_PATH}thumbnail_small.jpg"
  end


  # run algorithm process
  def detect_and_convert(canvas)
    logger.info "Fetching from facebook"
    self.remote_video_file_url = self.fb_src
    #if production fetch the video from s3
    if Rails.env.production?
      #get the video properties using mediainfo
    end
    logger.info "Getting video info"
    video_info = get_video_info
    unless video_info["Duration"].nil?
      dur = parse_duration_string video_info["Duration"]
      self.duration = dur
    end
    logger.info "converting to FLV"
    unless convert_to_flv video_info
      return false
    end
    #perform the face detection
    logger.info "Running detection"
    detect_face_and_timestamps video_file.current_path
    #saving only in facebook
    #self.remove_video_file
    #if fb_id
    update_attribute(:analyzed, true)
    #unless fb_id
    #  logger.info "Uploading to facebook"
    #  upload_video_to_fb(3, 500)
    #end
    #else
    #  update_att_after_upload_to_fb(result["id"])
    #end
    check_if_analyze_or_upload_is_done("analyze",canvas)
  end

  def upload_video_to_fb(retries, timeout, canvas)
    logger.info "uploading:  " + self.video_file.current_path
    result = fb_graph.put_video(self.video_file.current_path, { :title => self.title, :description => self.description })
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
      logger.info "Got it!!! upadating fb params, src:  #{fb_video["src"]}, picture: #{fb_video["picture"]}"
      update_attributes(:fb_uploaded => true, :fb_id => fb_video["id"], :fb_src => fb_video["source"], :fb_thumb => fb_video["picture"])
      check_if_analyze_or_upload_is_done("upload",canvas)
    end
  end

  def check_if_analyze_or_upload_is_done(operation, canvas)
    Video.connection.clear_query_cache
    video = Video.find(self.id)
    if (operation == "upload" and !video.analyzed) || (operation == "analyze" and !video.fb_uploaded)
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
      sleep(6)
      Video.connection.clear_query_cache
      video = Video.find(self.id)
      i = i + 1
    end
    #if canvas #FB notification
      send_fb_notification_to_user(fb_graph,video.user.fb_id,video.fb_id, video.title)
    #end
    return video.fb_id
  end


  def video_taggees_uniq
    VideoTaggee.find(:all, :select => "DISTINCT contact_info, fb_id", :conditions => { :video_id => self.id })
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
      else "Video has been deleted from site successfully but there was a problem deleting it from Facebook."
      end
    else
      "Video has been deleted from site successfully."
    end
  end

  def fb_destroy(graph)
    graph.delete_object(self.fb_id)
  end

  def fb_graph
    Koala::Facebook::API.new(self.user.fb_token)
  end

  # _____________________________________________ FLV/webm conversion functions _______________________

  def convert_to_flv video_info
    self.convert_to_flv!
    dims = get_width_height video_info
    cmd = convert_to_flv_command video_info, dims[0], dims[1]
    success = system(cmd  + " > #{Rails.root}/log/convertion.log")
=begin
    if dims[0] % 2 != 0
      dims[0] += 1
    end
    if dims[1] % 2 != 0
      dims[1] += 1
    end
    success = system(convert_to_webm_command video_info, dims[0], dims[1])
=end
    if success && $?.exitstatus == 0
      self.converted!
    else
      self.failed!
    end
  end

  def get_width_height video_info
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

  def set_new_filename
    #update_attribute(:source_file_name, "#{id}.flv")
    #debugger
    self.video_file = File.open(get_flv_file_name)
  end

  def s3_file_name
   "https://s3.amazonaws.com/#{Amazon::BUCKET}/test/#{filename}"
  end

  def get_flv_file_name
    dirname = Video.full_directory(id)
    File.join(dirname, "#{id}.flv")
  end

   def get_webm_file_name
    dirname = Video.full_directory(id)
    File.join(dirname, "#{id}.webm")
   end

   def get_h264_file_name
    dirname = Video.full_directory(id)
    File.join(dirname, "#{id}.mp4")
  end

  def convert_to_flv_command video_info, width, height
    output_file = self.get_flv_file_name
    File.open(output_file, 'w')
    command = <<-end_command
    ffmpeg -i #{ video_file.current_path } #{get_video_rotation_cmd video_info['Rotation']} -ar 22050 -ab 32 -acodec libmp3lame -s #{width}x#{height} -vcodec flv -r 25 -qscale 8 -f flv -y #{ output_file }
    end_command
    command.gsub!(/\s+/, " ")
    puts command
    command
  end

  def convert_to_webm_command video_info, width, height
    output_file = self.get_webm_file_name
    File.open(output_file, 'w')
    command = <<-end_command
    ffmpeg -i #{ video_file.current_path } #{get_video_rotation_cmd video_info['Rotation']} -c:v libvpx -ar 44100 -ab 96k -acodec libvorbis -s #{width}x#{height} -b 345k -y #{ output_file }
    end_command
    command.gsub!(/\s+/, " ")
    puts command
    command
  end

  def convert_to_h264_command video_info, width, height
    output_file = self.get_h264_file_name
    File.open(output_file, 'w')
    command = <<-end_command
    ffmpeg -i #{ video_file.current_path } #{get_video_rotation_cmd video_info['Rotation']}  -acodec libmp3lame -ab 96k -vcodec libx264 -level 21 -refs 2 -b 345k -bt 345k
    -threads 0 -s #{width}x#{height} -y #{ output_file }
    end_command
    command.gsub!(/\s+/, " ")
    puts command
    command
  end

  def get_video_info
    response =`mediainfo #{video_file.current_path} --Output=XML 2>&1`
    if response == nil
      return
    end
    xml_hash = Hash.from_xml response
    xml_hash['Mediainfo']['File']['track'][1]
  end

  def get_video_rotation_cmd degrees=nil
    #mediainfo_path = File.join( Rails.root, "Mediainfo", "Mediainfo")
    #response =`#{mediainfo_path} #{source.path} --output=json 2>&1`
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

  # _____________________________________________ FLV conversion functions _______________________

  #------------------------------------------------------ Class methods -------------------------------------------------------
  def self.uri(id)
    v=Video.find_by_id(id, :select => 'title')
    "/video/#{id}-#{PermalinkFu.escape(v.title)}"
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

  def self.full_directory_for_url(video_id)
    Video.full_directory(video_id).gsub("/","%2F")
  end

  def self.for_view(fb_id)
    video = Video.find_by_fb_id(fb_id)
  end

  # Moozly: the functions gets videos for showing in a list by sort order - latest or most popular  
  def self.get_videos_by_sort(page, order_by, sidebar, canvas, limit = MAIN_LIST_LIMIT)
    limit = 1000 if canvas
    sort = order_by == "latest" ? "created_at" : "views_count"
    vs = Video.paginate(:page => page, :per_page => limit).order("#{sort } desc")
    populate_videos_with_common_data(vs, sidebar, canvas, true) if vs
  end

  # Moozly: the functions gets videos for showing in a list by the video category
  def self.get_videos_by_category(category_id)
    vs = Video.find(:all, :conditions => { :category => category_id }, :order => "created_at desc", :limit => 10)
    populate_videos_with_common_data(vs, false, false) if vs
  end

  def self.get_videos_by_user(page, user_id, sidebar, canvas, limit = MAIN_LIST_LIMIT)
    #Moozly: temp limit for fb
    limit = 1000 if canvas
    vs = Video.where(:user_id => user_id).paginate(:page => page, :per_page => limit).order("created_at desc")
    populate_videos_with_common_data(vs, sidebar, canvas, name = false) if vs
  end

  def self.find_all_by_vtagged_user(user_fb_id)
    vs_ids = VideoTaggee.find_all_video_ids_by_user_id(user_fb_id)
    @vs = vs_ids.any? ? self.where("id in (#{vs_ids.join(",")})") : []
  end

  def self.populate_videos_with_common_data(vs, sidebar, canvas, name = false)
    vs.each do |v|
      user = v.user
      v[:user_id] = user.id
      v[:user_nick] = user.nick
      v[:thumb] = sidebar ? v.thumb_small_src : v.thumb_src
      v[:analyzed_ref] = "/#{'fb/' if canvas}video/#{v.fb_id}/#{v.analyzed ? 'edit_tags' : 'analyze'}"
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
      self.analysed!
    else
      self.failed!
    end
  end

  def get_avi_file_name
    File.join(Video.full_directory(:id), "#{id.to_s}.avi")
  end

  def get_timestamps_xml_file_name
    File.join(Video.full_directory(id), FACES_DIR, FACE_RESULTS)
  end

  def detect_command (filename)
    output_dir = faces_directory
    #input_file = File.join(Video.full_directory(id),id.to_s)
    input_file = filename
    if !File.exist?(input_file)
      input_file = video_file.current_path
    end

    "#{MOVIE_FACE_RECOGNITION_EXEC_PATH} Dreamline #{input_file} #{output_dir} #{HAAR_CASCADES_PATH} #{Rails.root.to_s}/public#{thumb_path_big} #{Rails.root.to_s}/public#{thumb_path_small}"
  end

  def faces_directory
    File.join(Video.full_directory(id), FACES_DIR)
  end

  def create_faces_directory
    Dir.mkdir(faces_directory)
    system("chmod -R 777 #{faces_directory}")
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
      taggee.save
      dir = File.dirname(face.attributes["path"])
      newFilename = File.join(dir, "#{taggee.id.to_s}.tif")
      File.rename(face.attributes["path"], newFilename)
      taggee.taggee_face = File.open(newFilename)
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
  def new_taggee_attributes=(taggee_attributes)
    taggee_attributes.each do |taggee|
      video_taggees.build(taggee)
    end
  end

  def existing_taggee_attributes=(taggee_attributes)
    video_taggees.reject(&:new_record?).each do |taggee|
      attributes = taggee_attributes[taggee.id.to_s]
      if attributes
        taggee.attributes = attributes
      else
        VideoTaggee.delete(taggee.id)
      end
    end
  end

  def save_taggees
    video_taggees.each do |t|
      #logger.info t.taggee_face.current_path
      #logger.info VideoTaggee.img_dir t.id
      t.save
    end
  end

  def delete_taggees
     self.video_taggees.destroy_all
  end

  #___________________________________________taggees handling______________________

  def to_player_json(default_face)
    resHash = { :name => self.title, :defaultCut => default_face }
    tags = VideoTaggee.find_all_by_video_id(id)
    cuts = []
    tags.each do |tag|
      unless tag.contact_info.empty?
        segs = TimeSegment.find_all_by_taggee_id(tag.id)
        times = []
        segs.each do |seg|
          times << [seg.begin / 1000, seg.end / 1000 + 1]
        end
        times = screen_and_unite_segments times
        cuts << { :name => tag.contact_info, :segments => times }
      end
    end
    cuts = unite_cuts_with_same_name cuts
    resHash[:cuts] = cuts
    resHash
  end

  def unite_cuts_with_same_name(cuts)
    new_cuts = []
    cuts.each_with_index do |cut|
      unless cut[:name] == ""
        cuts.each do |cut2|
          if cuts.index(cut) < cuts.index(cut2) && cut[:name] == cut2[:name]
            cut[:segments] << cut2[:segments]
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
    segments.delete_if {|i| i[0] == i[1]}
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
       File.open(file_path, 'w') {|f| f.write(j.encode(toWrite))}
  end

  def player_file_path
    "/tmp/player_cuts" + self.id.to_s + ".json"
  end

  def player_file__full_path
     TEMP_DIR_FULL_PATH + "/" + "player_cuts" + self.id.to_s + ".json"
  end

  def gen_player_file(current_user)
    unless Dir.exist? (TEMP_DIR_FULL_PATH)
      Dir.mkdir(TEMP_DIR_FULL_PATH, 0777)
    end
    nick = current_user ? current_user.nick : ""
    write_temp_player_file(nick, player_file__full_path)
    player_file_path
  end
end

