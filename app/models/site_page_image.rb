class SitePageImage < ApplicationRecord
	STYLES = ['hero', 'inset'].freeze

	belongs_to :depictable, polymorphic: true, touch: true
	validates :style, inclusion: { in: STYLES }
	validates :image_identifier, format: { with: /\A(doi|asset|lweb):/, message: "only doi, asset, lweb identifiers allowed" }
	validate :requires_captions_for_non_items

	def requires_captions_for_non_items
		return if image_identifier =~ /^doi:/
		if (caption.blank?)
			errors.add(:caption, "caption must be present for non-doi page image")
		end
	end
end