# This file houses our custom exceptions
module Exceptions
  # Exceptions related to importing subsites via the SubsiteImport Service
  class SubsiteUploadValidationError < StandardError
    def initialize(msg)
      super("There was an error validating the uploaded subsite: #{msg}")
    end
  end
  class SubsiteUploadError < StandardError
    def initialize(msg)
      super("There was an error processing the uploaded subsite: #{msg}")
    end
  end
end