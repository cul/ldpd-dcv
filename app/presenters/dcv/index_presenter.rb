# frozen_string_literal: true
module Dcv
  class IndexPresenter < Blacklight::IndexPresenter
    include Dcv::FieldPresenters
  end
end