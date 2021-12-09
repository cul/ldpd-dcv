# frozen_string_literal: true
module Dcv
  module FieldPresenters
    def field_presenter(field_config, options = {})
      presenter_class = (field_config.join == false) ? Dcv::UnjoinedFieldPresenter : Dcv::FieldPresenter
      presenter_class.new(view_context, document, field_config, options)
    end
  end
end