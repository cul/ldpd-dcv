# frozen_string_literal: true

module Iiif::Authz
  class AccessTokenResponseComponent < ViewComponent::Base
    def initialize(message:, origin:, **args)
      super
      @message = message
      @origin = origin
    end

    def message_json
      @message.to_json
    end

    def origin_json
      "\"#{@origin}\""
    end
  end
end
