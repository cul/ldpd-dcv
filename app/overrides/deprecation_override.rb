module Deprecation
  # Declare that a method has been deprecated.
  def self.deprecate_methods(target_module, *method_names)
    method_names.each { |method_name| Rails.logger.info("ignoring deprecation redefines on #{target_module}.#{method_name}") }
  end
end
