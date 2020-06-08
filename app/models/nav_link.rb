class NavLink < ActiveRecord::Base
	belongs_to :site

	def label
		sort_label =~ /^\d+\s*:\s*(.*)/ ? $1 : sort_label
	end
end