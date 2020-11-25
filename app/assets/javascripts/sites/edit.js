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

function addNavMenu(addButton) {
	// build a template nav menu
	var newMenu = $(".nav-templates > .site_navigation_menu").clone();
	var menuNumber = $(".site_navigation > .site_navigation_menu").length;
	var menuIndex = menuNumber;
	// index and number can drift based on menu removal and sorting, so verify index
	while($("#site_navigation_menu_" + menuIndex).length > 0) {
		menuIndex++;
	}
	var re = /9menuIndex9/;
	newMenu.attr('id', newMenu.attr('id').replace(re, menuIndex.toString()));
	// update all template id, for, name, data-target, data-parent, aria-controls attribute values
	['id', 'data-target', 'data-parent', 'aria-controls'].forEach(function(att){
		newMenu.find("[" + att + "]").each(function(){
			$(this).attr(att, $(this).attr(att).replace(re, menuIndex.toString()));
		});
	});
	['for', 'name'].forEach(function(att){
		newMenu.find("[" + att + "]").each(function(){
			$(this).attr(att, $(this).attr(att).replace(re, menuNumber.toString()));
		});
	});
	// append it after last menu
	newMenu.insertBefore($(addButton));
}

function addNavLink(addButton) {
	var navLinks = addButton.parentNode;
	// build a template nav link
	var newLink = $(".nav-templates > .site_navigation_link").clone();
	var linkNumber = $(navLinks).children(".site_navigation_link").length;
	var linkIndex = linkNumber;
	var menuIndex = navLinks.getAttribute('id').match(/\d+$/)[0];
	var menuNumber = navLinks.getAttribute('id').match(/\d+$/)[0];
	var navMenu = $(navLinks).parentElement;
	// index and number can drift based on menu removal and sorting, so find both
	var menuLabel = $("#site_nav_menus_attributes_" + menuIndex + "_label")[0];
	var menuNumber = menuLabel.getAttribute('name').match(/\[\d+\]/g)[0].replaceAll(/[\[\]]/g,'');
	// ensure link number and index are both valid
	while($("#site_nav_menus_attributes_" + menuIndex + "_links_attributes_" + linkIndex + "_label").length > 0) {
		linkIndex++;
	}
	var mre = /9menuIndex9/;
	var lre = /9linkIndex9/;
	// update all template id, for, name, data-target, data-parent, aria-controls attribute values
	['id', 'data-target', 'data-parent', 'aria-controls'].forEach(function(att){
		newLink.find("[" + att + "]").each(function(){
			$(this).attr(att, $(this).attr(att).replace(mre, menuIndex.toString()).replace(lre, linkIndex.toString()));
		});
	});
	['for', 'name'].forEach(function(att){
		newLink.find("[" + att + "]").each(function(){
			$(this).attr(att, $(this).attr(att).replace(mre, menuNumber.toString()).replace(lre, linkNumber.toString()));
		});
	});
	// append it after last link
	newLink.insertBefore($(addButton));
	sortableLinks($(".site_navigation_links"));
}

function addTextBlock(addButton) {
	// build a template text block
	var newBlock = $(".new-block-template .site_text_block").clone();
	var blockNumber = $(".site_text_blocks > .site_text_block").length;
	var blockIndex = blockNumber;
	// index and number can drift based on menu removal and sorting, so verify index
	while($("#site_text_block_" + blockIndex).length > 0) {
		blockIndex++;
	}
	var re = /9blockIndex9/;
	newBlock.attr('id', newBlock.attr('id').replace(re, blockIndex.toString()));
	// update all template id, for, name, data-target, data-parent, aria-controls attribute values
	['id', 'data-target', 'data-parent', 'aria-controls'].forEach(function(att){
		newBlock.find("[" + att + "]").each(function(){
			$(this).attr(att, $(this).attr(att).replace(re, blockIndex.toString()));
		});
	});
	['for', 'name'].forEach(function(att){
		newBlock.find("[" + att + "]").each(function(){
			$(this).attr(att, $(this).attr(att).replace(re, blockNumber.toString()));
		});
	});
	// append it after last menu
	newBlock.insertBefore($(addButton));
	new EasyMDE({
				element: newBlock.find('textarea')[0],
				forceSync: true,
				autoRefresh: { delay: 250 }
	});

}

function removeNavMenu(button) {
	$(button).closest(".site_navigation_menu").remove();
	$(".site_navigation > .site_navigation_menu").each(reassignNavMenuIndexes);
}

function removeNavLink(button) {
	var navMenu = $(button).closest(".site_navigation_menu");
	$(button).closest(".site_navigation_link").remove();
	reassignNavLinkIndexes(navMenu);
}

function removeTextBlock(button) {
	var allBlocks = $(button).closest(".site_text_blocks");
	$(button).closest(".site_text_block").remove();
	reassignTextBlockIndexes(allBlocks);
}

/******************
 * EVENT HANDLERS *
 ******************/

function navMenuPositionUpdated(event, ui) {
	$(ui.item[0].parentElement).children(".site_navigation_menu").each(reassignNavMenuIndexes);
}

function reassignNavMenuIndexes(index, navMenu) {
	// new menu prefix is site[nav_menus_attributes][$index]
	var re = /site\[nav_menus_attributes\]\[\d+\]/;
	var sub = "site[nav_menus_attributes][" + index + "]";
	$(navMenu).find('label').each(function(mIndex, ele){
		// change the for attribute for the new menu prefix
		var oldVal = $(ele).attr('for');
		if (!oldVal) return;
		$(ele).attr('for', oldVal.replace(re, sub));
	});
	$(navMenu).find('input').each(function(mIndex, ele){
		if ($(ele).attr('type') == 'button') return;
		// change the name attribute for the new menu prefix
		var newVal = $(ele).attr('name').replace(re, sub);
		$(ele).attr('name', newVal);
	});
}

function navLinkPositionUpdated(event, ui) {
	reassignNavLinkIndexes(ui.item[0].parentElement);
	if (ui.sender && !(ui.sender == ui.item[0].parentElement)) {
		reassignNavLinkIndexes(ui.sender);
		$(".site_navigation > .site_navigation_menu").each(reassignNavMenuIndexes);
	}
}

function reassignNavLinkIndexes(navMenu) {
	$(navMenu).find(".site_navigation_link").each(function(index, navLink) {
		// new link prefix will be site[nav_menus_attributes][$menuIndex][link_attributes][$index]
		var re = /(site\[nav_menus_attributes\]\[\d+\]\[links_attributes\])\[\d+\]/;
		var sub = "$1[" + index + "]";
		$(navLink).find('label').each(function(){
			// change the for attribute for the new link prefix
			var oldVal = $(this).attr('for');
			if (!oldVal) return;
			$(this).attr('for', oldVal.replace(re, sub));
		});
		$(navLink).find('input').each(function(){
			if ($(this).attr('type') == 'button') return;
			// change the name attribute for the new link prefix
			var newVal = $(this).attr('name').replace(re, sub);
			$(this).attr('name', newVal);
		});
	});
}

function sortableLinks(selection) {
	selection.sortable({
		'items': '.site_navigation_link',
		'containment': '.site_navigation',
		'axis': 'y',
		'handle': '.site_navigation_link_handle',
		'connectWith': '.site_navigation_links',
		'cursor': 'move',
		'opacity': 1.0,
		'update': navLinkPositionUpdated
	});
}

function textBlockPositionUpdated(event, ui) {
	reassignTextBlockIndexes(ui.item[0].parentElement);
}

function reassignTextBlockIndexes(textBlocks) {
	$(textBlocks).find(".site_text_block").each(function(index, textBlock) {
		// new link prefix will be page[site_text_blocks_attributes][$index]
		var re = /(site_page\[site_text_blocks_attributes\])\[\d+\]/;
		var sub = "$1[" + index + "]";
		$(textBlock).find('label').each(function(){
			// change the for attribute for the new link prefix
			var oldVal = $(this).attr('for');
			if (!oldVal) return;
			$(this).attr('for', oldVal.replace(re, sub));
		});
		var repl = function(){
			if ($(this).attr('type') == 'button') return;
			// change the name attribute for the new link prefix
			var newVal = $(this).attr('name').replace(re, sub);
			$(this).attr('name', newVal);
		};
		$(textBlock).find('input[name]').each(repl);
		$(textBlock).find('textarea[name]').each(repl);
	});
}

function sortableTextBlocks(selection) {
	selection.sortable({
		'items': '.site_text_block',
		'containment': '.site_text_blocks',
		'axis': 'y',
		'handle': '.site_text_block_handle',
		'cursor': 'move',
		'opacity': 1.0,
		'update': textBlockPositionUpdated
	});
}

/***********
 * ON LOAD *
 ***********/
$(function() {
	$(window).on('load', function() {
		// make nav groups container sortable
		$(".site_navigation").sortable({
			'items': '.site_navigation_menu',
			'containment': 'parent',
			'axis': 'y',
			'handle': '.site_navigation_menu_handle',
			'cursor': 'move',
			'opacity': 1.0,
			'update': navMenuPositionUpdated
		});
		// make each nav group sortable
		sortableLinks($(".site_navigation_links"));
		// make each text block sortable
		sortableTextBlocks($(".site_text_blocks"));
		$(".site_text_blocks textarea").each(function() {
			new EasyMDE({
				element: this,
				forceSync: true,
				autoRefresh: { delay: 250 },
				initialValue: $(this).val()
			});
		});
	});
});
