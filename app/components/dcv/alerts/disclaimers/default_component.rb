# frozen_string_literal: true

module Dcv::Alerts::Disclaimers
  class DefaultComponent < ViewComponent::Base
    delegate :current_user, :has_restricted_children?, :has_unviewable_children?, to: :helpers
    def initialize(document:, asset: nil)
      @document = document
    end
  end
end