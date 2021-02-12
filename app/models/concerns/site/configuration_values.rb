module Site::ConfigurationValues
	def boolean_or_nil(val)
		return nil if val.blank? && (false != val)
		(val.to_s =~ /true/i) ? true : false
	end

	def float_or_nil(val)
		return val.to_f unless val.blank?
		nil
	end

	def int_or_nil(val)
		return val.to_i unless val.blank?
		nil
	end

	def clean_and_freeze_array(val)
		Array(val).compact.map(&:to_s).freeze
	end

	def clean_and_freeze_validated_array(val, valid_values = [])
		(Array(val).compact.map(&:to_s) & valid_values).freeze
	end

	def valid_or_nil(val, valid_values = [])
		val if valid_values.include?(val)
	end
end
