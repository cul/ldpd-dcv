module Iiif::Behavior
	module V3
		# Temporal Behaviors
		AUTO_ADVANCE    = 'auto-advance'
		NO_AUTO_ADVANCE = 'no-auto-advance'
		REPEAT          = 'repeat'
		NO_REPEAT       = 'no-repeat'
		# Layout Behaviors
		UNORDERED    = 'unordered'
		INDIVIDUALS  = 'individuals'
		CONTINUOUS   = 'continuous'
		PAGED        = 'paged'
		FACING_PAGES = 'facing-pages'
		NON_PAGED    = 'non-paged'
		# Collection Behaviors
		# Range Behaviors
		SEQUENCE      = 'sequence'
		THUMBNAIL_NAV = 'thumbnail-nav'
		NO_NAV        = 'no-nav'
		# Miscellaneous Behaviors
		HIDDEN = 'hidden'
		# CUL Behavior extensions
		NO_DOWNLOAD = "no-download"
		STREAMING = 'streaming'
	end
end