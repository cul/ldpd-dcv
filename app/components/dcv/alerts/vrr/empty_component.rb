# frozen_string_literal: true

module Dcv::Alerts::Vrr
  class EmptyComponent < ViewComponent::Base
    delegate :current_user, to: :helpers
  end
end