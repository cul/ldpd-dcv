class SitePage < ActiveRecord::Base
	has_many :site_text_blocks, dependent: :destroy
	belongs_to :site
	validates :columns, inclusion: { in: (1..2) }
	validates_uniqueness_of :slug, scope: :site_id
	accepts_nested_attributes_for :site_text_blocks

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
	def site_text_blocks_attributes=
	end
end