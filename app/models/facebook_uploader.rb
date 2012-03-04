class FacebookUploader < Struct.new(:graph, :video)
  def perform
    result = graph.put_video(video.video_file.current_path, { :title => video.title, :description => video.description })
    puts "1"
    unless result.nil?
      puts "2"
      puts "self is:" + self.id.to_s
      #puts self.to_s
      puts "fbid is:" + result["id"]
      video.update_attributes(:fbid => result["id"])
      puts "3"
    end
    puts "4"
  end
end