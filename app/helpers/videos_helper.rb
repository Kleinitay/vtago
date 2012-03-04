module VideosHelper

    def fields_for_taggee(taggee, &block)
        prefix = taggee.new_record? ? 'new' : 'existing'
        fields_for("video[#{prefix}_taggee_attributes][]", taggee, &block)
    end

    def add_taggee_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :VideoTaggees, :partial => 'video_taggees/video_taggee', :object => VideoTaggee.new
        end
    end
    
    def gallery_class_helper  
       if @gallery_var<2
          @gallery_var=@gallery_var+1
          @dynamic_class="edit_box_center"
       else
           @gallery_var=0
           @dynamic_class="edit_box_last"
       end
    end


end
