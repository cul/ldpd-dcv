class PagesController < ApplicationController

  layout 'dcv'

  def wall
  end

  def about
  end
  
  def robots
    #respond_to :text
    expires_in 6.hours, public: true
    
    environment_robots_file_path = File.join('config/robots', Rails.env + '.txt')
    unless File.exists?(environment_robots_file_path)
      environment_robots_file_path = File.join('config/robots/default.txt')
    end
    
    send_file environment_robots_file_path, disposition: 'inline', :type => 'text/plain'
  end

end
