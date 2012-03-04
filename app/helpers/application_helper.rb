module ApplicationHelper

  # Moozly: for showing nice video duration like 03:04
  def nice_duration(seconds)
    h = (seconds/3600).floor
    m = ((seconds - (h * 3600))/60).floor
    s = (seconds - (h * 3600 + m * 60)).round

    # return formatted time without hours if = 0
    hours = h == 0 ? "" : "#{'%02d' % h}:"
    return "#{hours}#{'%02d:%02d' % [ m, s ]}"
  end
  
  # Moozly: uses rails helper with the word "ago"
  def nice_time_ago_in_words(time)
    case
      when !time                 then ''
      when time < 7.days.ago     then time.strftime("%b %d, %Y")
      when time < 60.seconds.ago then time_ago_in_words(time) + " ago"
      else
        "Seconds ago"
    end
  end
  

  def nice_time_ago_with_year(time)
    distance_in_minutes = ((Time.now - time).to_i) / 60
    case distance_in_minutes
      when 0 then "Seconds ago"
      when 1..59                      then "#{distance_in_minutes} minute#{"s" if distance_in_minutes > 1} ago"
      when 60..1439                   then "#{distance_in_minutes / 60} hour#{"s" if distance_in_minutes > 120} ago"
      when 1440..10079                then "#{distance_in_minutes / (60*24) } day#{"s" if distance_in_minutes > 2880} ago"
      else                            time.strftime("%b %e#{", %Y" if time.year != Time.now.year}")
    end
  end

  def nice_time_ago_in_words_including_day_name(time)
    case
      when !time                 then ''
      when time < 7.days.ago     then time.strftime("%a, %b %d, %Y")
      when time < 60.seconds.ago then time_ago_in_words(time) + " ago"
      else
        "Seconds ago"
    end
  end
  
  def nice_how_many_comments(num)
    number = num.to_i
    if number == 0
		  "Comment!"
    elsif number == 1
        "1 Comment"
    else
      "#{number} Comments"
    end
  end

  def nice_how_many_string(num, string)
    number = num.to_i
    if number == 1
		  string
    else
      "#{string}s"
    end
  end
  
  #pnina this helpers are here for creating one place from where pictures will be pulled
  def logo(size="60x60")
     image_tag("vtago.png",:size => size, :id=>'logo',:border=>"0" )   
  end
  
  def fb_profile_pic(size, nick, user_id)
    src = User.profile_pic_src(user_id)
    image_tag(src,:size=> size,:class=>'profile_pic', :alt=> nick)
  end
end
