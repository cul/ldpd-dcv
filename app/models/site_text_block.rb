require 'uri'
class SiteTextBlock < ApplicationRecord
	belongs_to :site_page, touch: true
	has_many :site_page_images, dependent: :destroy, as: :depictable

	def label
		self.sort_label =~ /^\d+\:\s*(.*)/ ? $1 : self.sort_label
	end

	def self.export_filename_for_sort_label(sort_label)
		sort_label = sort_label.dup
		sort_label.sub!(/^(\d{1,2})\:/) { |m| "#{'%02d_' % m[1].to_i}" }
		filename = sort_label.gsub(' ', '_')
		filename = URI.encode_www_form_component(filename)
		"#{filename}.md"
	end

	def self.sort_label_from_filename(filename)
		label = File.basename(filename, ".md")
		label.sub!(/^([\d]{1,2})_/) { |m| '%02d:' % m[1].to_i }
		label = URI.decode_www_form_component(label)
		label.gsub!('_',' ')
		label
	end
end