class NavLink < ActiveRecord::Base
	belongs_to :site, touch: true
	validates_presence_of [:sort_label, :link]

	def label
		sort_label =~ /^\d+\s*:\s*(.*)/ ? $1 : sort_label
	end
	# links to a internally-managed about page are usefully identified
	def about_link?
		self.external == false && self.link == 'about'
	end
end