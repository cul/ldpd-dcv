module Dcv::RestrictableController
  extend ActiveSupport::Concern

  def restricted?
    self.class.restricted?
  end

  module ClassMethods
    def restricted?
      return controller_path.start_with?('restricted/')
    end
  end
end