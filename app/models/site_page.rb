class SitePage < ActiveRecord::Base
	has_many :site_text_blocks, dependent: :destroy
	belongs_to :site, touch: true
	validates :columns, inclusion: { in: (1..2) }
	validates_uniqueness_of :slug, scope: :site_id
	validate :home_slug_does_not_change
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
	def site_text_blocks_attributes=(atts_map)
		unrolled_atts = atts_map.map {|ix, atts| atts.merge('sort_label' => "#{sprintf("%02d", ix.to_i)}:#{atts.delete('label')}")}
		if unrolled_atts.detect {|ua| ua['markdown'].present? }
			self.site_text_blocks.each do |text_block|
				if unrolled_atts.present?
					# update this available text block record
					atts = unrolled_atts.shift
					# sanitize script elements
					atts['markdown']&.gsub!(/<(\/?script[^>]*)>/i, '&lt;\1&gt;')
					text_block.update_attributes! atts
				else
					# out of attributes so delete remaining text blocks
					text_block.delete
				end
			end
			# remaining attributes represent new nav links that must be added
			unrolled_atts.each do |text_block_attributes|
				self.site_text_blocks.create!(text_block_attributes)
			end
		end
	end

	def home_slug_does_not_change
		if (slug_was == 'home' && slug_changed?)
			errors.add(:slug, "cannot modify slug of home page")
		end
	end
end