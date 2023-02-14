module Dcv::Components
  module StructuredChildrenBehavior
    def structured_children
      @structured_children ||= helpers.structured_children(@document)
    end
  end
end