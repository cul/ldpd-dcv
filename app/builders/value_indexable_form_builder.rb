class ValueIndexableFormBuilder < ActionView::Helpers::FormBuilder
	def text_field(method, options = {})
		v = super
		value_index = options["value_index"] || options[:value_index]
		if value_index
			rep = 'id="\1_' + value_index.to_s + '"'
			v.sub!(/id=\"(.*)\"/, rep)
		end
		v.html_safe
	end
end