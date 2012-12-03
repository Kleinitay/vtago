FactoryGirl.define do
  factory :video_short, class: Video do
    title "short"
    duration  1
    category 1
    status_id 1
    video_file File.open("#{Rails.root}/TestVideos/shortest.wmv")
  end

  # This will use the User class (Admin would have been guessed)
  factory :empty_video, class: Video do
    title "empty"
    duration  1
    category 1
    status_id 1
  end


end
