# frozen_string_literal: true

module Dcv::Footer
  class ContactComponent < ViewComponent::Base
    delegate :site_edit_link, :terms_of_use_url, to: :helpers
  end
end