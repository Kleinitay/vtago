FactoryGirl.define do
  factory :user_itay, class: User do
    fb_id 645113644
    email "klein.itay@hotmail.com"
    nick "Itay Klein"
    password "asdf"
    status 2
  end

  factory :user_eli, class: User do
    email "elinor.dreamer@gmail.com"
    nick "Elinor Dreamer"
    fb_id 665131761
    password "asdf"
    status 2
  end

  factory :user_eyal, class: User do
    email "eyal.zach@gmail.com"
    nick "Eyal Zach"
    fb_id 620974828
    password "asdf"
    status 2
  end

  factory :user_itikos, class: User do
    email "klein.itay@gmail.com"
    nick "Itikos Kleinos"
    fb_id 100003675844884
    password "asdf"
    status 2
  end

end