module Api
  module V1
    class ExternalDisplayController < ApplicationController
      rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

      def info
        result = Api::InfoService.new(
          item_id,
          asset_id
        ).call

        if result.success?
          render json: result.data, status: result.status
        else
          render_error(
            code: result.error_code,
            message: result.error_message,
            status: result.status
          )
        end
      end

      private

      def item_id
        params.require(:itemId)
      end

      def asset_id
        params.require(:assetId)
      end

      def render_error(code:, message:, status:)
        render json: {
          error: {
            code: code,
            message: message
          }
        }, status: status
      end

      def handle_parameter_missing(exception)
        render_error(
          code: 'missing_parameter',
          message: exception.message,
          status: :bad_request
        )
      end
    end
  end
end