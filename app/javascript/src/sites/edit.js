import EasyMDE from 'easymde'; 

function addValueFieldsetFromTemplate(addButtonFieldset, templateName) {
	const newFieldset = $(".widget-templates").find("fieldset[name='" + templateName + "']").clone();
	const valueNumber = $(addButtonFieldset.parentNode).children("fieldset[name='" + templateName + "']").length;
	var valueIndex = valueNumber;
	// index and number can drift based on value removal, so verify index
	while($("#" + templateName + "_" + valueIndex).length > 0) {
		valueIndex++;
	}
	var re = /9valueIndex9/;
	// update all template id, for, name, data-target, data-parent, aria-controls attribute values
	['id', 'data-target', 'data-parent', 'aria-controls'].forEach(function(att){
		newFieldset.find("[" + att + "]").each(function(){
			$(this).attr(att, $(this).attr(att).replace(re, valueIndex.toString()));
		});
	});
	['for', 'name'].forEach(function(att){
		newFieldset.find("[" + att + "]").each(function(){
			$(this).attr(att, $(this).attr(att).replace(re, valueNumber.toString()));
		});
	});
	newFieldset.insertBefore($(addButtonFieldset));
}

export function addNavMenu(addButton) {
	// build a template nav menu
	var newMenu = $(".widget-templates > .site_navigation_menu").clone();
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
	addTooltips(newMenu);
}

export function addNavLink(addButton) {
	var navLinks = addButton.parentNode;
	// build a template nav link
	var newLink = $(".widget-templates > .site_navigation_link").clone();
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
	addTooltips(newLink);
}

export function addTextBlock(addButton) {
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
	// append it after last menu but before the add button
	// removed blocks are after the button
	newBlock.insertBefore($(addButton));
	addTooltips(newBlock);
	addMarkdownEditors(newBlock);
	reassignTextBlockIndexes($(addButton).closest(".site_text_blocks"));
}

export function addFacetFieldFields(addButton) {
	addFieldFields(addButton, 'facet_field')
}

export function addSearchFieldFields(addButton) {
	addFieldFields(addButton, 'search_field')
}

export function addScopeFilterFields(addButton) {
	addFieldFields(addButton, 'scope_filter')
}

function addFieldFields(addButton, fieldType) {
	// build a template text block
	var newField = $(".widget-templates > ." + fieldType).clone();
	var fieldNumber = $("." + fieldType + "s > ." + fieldType).length;
	var fieldIndex = fieldNumber;
	// index and number can drift based on menu removal and sorting, so verify index
	while($("#" + fieldType + "s_" + fieldIndex).length > 0) {
		fieldIndex++;
	}
	var re = /9fieldIndex9/;
	newField.attr('id', newField.attr('id').replace(re, fieldIndex.toString()));
	// update all template id, for, name, data-target, data-parent, aria-controls attribute values
	['id', 'data-target', 'data-parent', 'aria-controls'].forEach(function(att){
		newField.find("[" + att + "]").each(function(){
			$(this).attr(att, $(this).attr(att).replace(re, fieldIndex.toString()));
		});
	});
	['for', 'name'].forEach(function(att){
		newField.find("[" + att + "]").each(function(){
			$(this).attr(att, $(this).attr(att).replace(re, fieldNumber.toString()));
		});
	});
	// append it after last menu
	newField.insertBefore($(addButton));
	addTooltips(newField);
}

export function removeNavMenu(button) {
	$(button).closest(".site_navigation_menu").remove();
	$(".site_navigation > .site_navigation_menu").each(reassignNavMenuIndexes);
}

export function removeNavLink(button) {
	var navMenu = $(button).closest(".site_navigation_menu");
	$(button).closest(".site_navigation_link").remove();
	reassignNavLinkIndexes(navMenu);
}

export function removeTextBlock(button) {
	var allBlocks = $(button).closest(".site_text_blocks");
	var block = $(button).closest(".site_text_block");
	block.hide();
	block.find('.destroy_flag').attr('value', '1');
	block.remove();
	// append to end if it was an existing block that needs to be deleted
	if (block.find('.text_block_id').attr('value') != "") allBlocks.append(block);
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

function addMarkdownEditors(selection) {
	selection.find("textarea").each(function() {
		new EasyMDE({
			element: this,
			forceSync: true,
			autoRefresh: { delay: 250 },
			initialValue: $(this).val()
		});
	});	
}

function addTooltips(selection) {
	selection.find("span[data-tooltip]").each(function(){
		var tooltip = $('#' + $(this).attr('data-tooltip'));
		var options = {
			content: tooltip.html(),
			title: tooltip.attr('title'),
			container: 'body',
			viewport: 'body',
			placement: 'top',
			trigger: 'click focus',
			html: true
		};
		$(this).on('click',function(e){ e.preventDefault(); }).tooltip(options);
	});
}
/************
 * ON READY *
 ************/
export function onReady() {
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
	addMarkdownEditors($(".site_text_blocks"));
	addTooltips($("form"));
};
