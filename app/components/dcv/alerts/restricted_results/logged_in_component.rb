# frozen_string_literal: true

module Dcv::Alerts::RestrictedResults
  class LoggedInComponent < ViewComponent::Base
    delegate :current_user, :terms_of_use_url, to: :helpers
  end
end