module Dcv::Catalog::AlternateHomePages
  extend ActiveSupport::Concern

  def home2
    render 'catalog/alternate_home_pages/home2', layout: 'home2'
  end

  def home3
    render 'catalog/alternate_home_pages/home3', layout: 'home3'
  end

end
