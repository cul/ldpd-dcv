class SitePage < ApplicationRecord
	has_many :site_text_blocks, dependent: :destroy, inverse_of: :site_page
	has_many :site_page_images, dependent: :destroy, as: :depictable
	belongs_to :site, touch: true
	validates :columns, inclusion: { in: (1..2) }
	validates_uniqueness_of :slug, scope: :site_id
	validate :home_slug_does_not_change
	validates_associated :site_page_images
	accepts_nested_attributes_for :site_text_blocks, allow_destroy: true
	accepts_nested_attributes_for :site_page_images, allow_destroy: true

	def initialize(atts = {})
		super
		title ||= slug && slug.split('_').join(' ').titlecase
	end

	def has_columns?
		columns > 1 && site_text_blocks.length > 1
	end

		# currently will partition into two columns maximum
	def text_block_columns
		block_partition = (site_text_blocks.length.to_f / 2).ceil
		sorted_blocks = site_text_blocks.sort { |a,b| a.sort_label <=> b.sort_label }
		[sorted_blocks[0...block_partition], sorted_blocks[block_partition..-1]]
	end

	def use_multiple_columns
		columns > 1
	end

	def use_multiple_columns=(val)
		columns = val ? 2 : 1
	end

	# this setter is necessary for the form builder
	def site_text_blocks_attributes=(atts_map)
		atts_map.each { |ix, atts| atts['sort_label'] = "#{sprintf("%02d", ix.to_i)}:#{atts.delete('label')}" }
		super
	end

	def home_slug_does_not_change
		if (slug_was == 'home' && slug_changed?)
			errors.add(:slug, "cannot modify slug of home page")
		end
	end
end