module SolrDocument::PublicationInfo
	extend ActiveSupport::Concern

	def unpublished_origin_information(field)
		if field =~ /(.+)(\(\d+\))$/
			field = $1
		end
		place = self.fetch(:origin_info_place_for_display_ssm,[]).first
		date = self.fetch(field,[]).first
		date << '.' unless date.nil? || place.nil? || date[-1] == '.'
		[place, date].compact
	end

	def published_origin_information(field)
		if field =~ /(.+)(\(\d+\))$/
			field = $1
		end
		publisher = self.fetch(:lib_publisher_ssm,[]).first
		publisher = Array.wrap(publisher)

		place = self.fetch(:origin_info_place_for_display_ssm,[]).first
		publisher << place if place
		publisher.each { |part| part.sub!(/[\s\:\.]+$/,'') }
		publisher = publisher.join(': ')
		# Carnegie: origin_info_date_created_ssm
		# Durst: lib_date_textual_ssm
		date = self.fetch(field,[]).first
		date.sub!(/[\s\:\.]+$/,'') unless date.nil?
		[publisher, date].compact.join('. ')
	end
end