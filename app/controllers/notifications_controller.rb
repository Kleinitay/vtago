class NotificationsController < ApplicationController
  layout nil

  before_filter :authorize

  def all
    @notifications = current_user.notifications
  end

  def unviewed_count
    render :json =>  current_user.notifications.unviewed.count 
  end

  def mark_viewed
    n = current_user.notifications.find(params[:id])
    n.mark_viewed!
    render :json => { :success => true }
  end
end
