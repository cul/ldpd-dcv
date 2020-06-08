class SiteTextBlock < ActiveRecord::Base
	belongs_to :site_page

	def label
		sort_label =~ /^\d+\:\s*(.*)/ ? $1 : sort_label
	end
end