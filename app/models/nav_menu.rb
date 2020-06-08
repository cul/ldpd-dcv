class NavMenu
	attr_reader :sort_label, :links
	delegate :length, to: :@links

	def initialize(sort_label)
		@sort_label = sort_label
		@links = []
	end

	def label
		@sort_label =~ /^\d+\s*:\s*(.*)/ ? $1 : @sort_label
	end
end