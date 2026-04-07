class AdminController < ActionController::Base
  layout 'admin'

  def index
  end

  def subsite_upload_show
    @upload = 'example subsite'
  end

  def subsite_upload
  end
end
