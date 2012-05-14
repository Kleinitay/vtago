# == Schema Information
#
# Table name: email_subscribed_users
#
#  id         :integer(4)      not null, primary key
#  email      :string(255)     not null
#  created_at :datetime
#  updated_at :datetime
#

class EmailSubscribedUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :video

  validates_uniqueness_of :email, :message => "An Invite was already sent to this e-mail address before."
end
