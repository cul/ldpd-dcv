class TestRouteHelper
	attr_reader :_routes
	def initialize(app: Rails.application, view_context: nil)
		app.routes.tap do |route_set|
			@_routes = route_set
			self.extend(route_set.named_routes.url_helpers_module)
			self.extend(route_set.named_routes.path_helpers_module)
		end
		@view_context = view_context
	end
	def url_options
		{ host: 'http://localhost' }
	end
	def view_context
		@view_context
	end
end