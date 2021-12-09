module Dcv
  class DocumentPresenter < Blacklight::DocumentPresenter
    include Dcv::FieldPresenters
  end
end