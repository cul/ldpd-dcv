module Dcv::Catalog::CatalogLayout
  extend ActiveSupport::Concern

  module ClassMethods
    def subsite_key
      'catalog'
    end

    def subsite_config
      @subsite_config ||= load_subsite&.to_subsite_config || {}
    end

    def load_subsite
      @subsite ||= Site.find_by(slug: subsite_key)
    end
  end

  def subsite_key
    self.class.subsite_key
  end

  def subsite_config
    @subsite_config ||=  self.class.subsite_config
  end

  def load_subsite
    @subsite ||= self.class.load_subsite
  end

  def subsite_styles
    (super + [subsite_key]).uniq
  end

end
