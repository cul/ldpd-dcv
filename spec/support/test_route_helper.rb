class TestRouteHelper
	attr_reader :_routes
	def initialize(app = Rails.application)
		app.routes.tap do |route_set|
			@_routes = route_set
			self.extend(route_set.named_routes.url_helpers_module)
			self.extend(route_set.named_routes.path_helpers_module)
		end
	end
	def url_options
		{host: 'http://localhost'}
	end
end