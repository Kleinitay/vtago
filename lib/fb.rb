module Fb
  def self.send_notification(fb_graph,user_fb_id,video_fb_id, title, message) # change to nitification

   name = "VtagO - #{title}"
   link = "http://www.vtago.com/video/#{video_fb_id}"

   fb_graph.put_object(user_fb_id, 'apprequests', {:message => message}, {"name" => name, "link" => link })
   #fb_graph.put_wall_post("", { "name" => name, "link" => link, "caption" => message}, "#{user_fb_id}")
  end

  def self.remove_notification(fb_graph, id)
    fb_graph.delete_object(id)
  end
end

