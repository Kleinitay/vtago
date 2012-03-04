# == Schema Information
#
# Table name: time_segments
#
#  id         :integer(4)      not null, primary key
#  taggee_id  :integer(4)
#  begin      :integer(4)
#  end        :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

class TimeSegment < ActiveRecord::Base
    belongs_to :video_taggee, :dependent => :destroy
end
