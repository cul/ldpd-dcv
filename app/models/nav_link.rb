class NavLink < ActiveRecord::Base
	belongs_to :site
	validates_presence_of [:sort_label, :link]

	def label
		sort_label =~ /^\d+\s*:\s*(.*)/ ? $1 : sort_label
	end
end