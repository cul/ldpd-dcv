function addSiteImageUriFieldSet(addButtonFieldset) {
	const newIndex = document.getElementsByName('site_image_uris').length;
	// <fieldset name="site_image_uris" style="border-width: 0 0 2px 0;">
	const newFieldset = document.createElement("fieldset");
	newFieldset['name'] = 'site_image_uris';
	newFieldset['className'] = 'paneled';
	// <input value="" id="site_image_uris[1]" type="text" name="site[image_uris][]">
	const newInput = document.createElement("input");
	newInput['type'] = 'text';
	newInput['name'] = 'site[image_uris][]';
	newInput['id'] = 'site_image_uris[' + newIndex + ']';
	newFieldset.appendChild(newInput);
	// <input type="button" class="btn btn-danger" value="Remove" onclick="this.parentElement.remove();"/>
	if (newIndex > 0) {
		const newButton = document.createElement("input");
		newButton['type'] = 'button';
		newButton['className'] = 'btn btn-danger';
		newButton['value'] = 'Remove';
		newButton['onclick'] = function() { this.parentElement.remove() };
		newFieldset.appendChild(newButton);
	}
	addButtonFieldset.parentNode.insertBefore(newFieldset, addButtonFieldset);
}