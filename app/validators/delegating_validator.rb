class DelegatingValidator < ActiveModel::Validator
	def validate(record)
		return unless options[:fields].any?
		options[:fields].each { |field| record.send(field).validate(field, record.errors) }
	end
end
