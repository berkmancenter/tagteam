$(document).ready(function(){
	$('#feed_feed_url_input p.inline-hints').click(function(){
		$.ajax({
			type: 'POST',
			cache: false,
			dataType: 'json',
			url: $.rootPath()  + 'feeds/check_feed',
			data: {
				feed_url: $('#feed_feed_url').val()
			},
			beforeSend: function(){
				$('#feed_feed_url_input p.inline-hints').append('<img src="' + $.rootPath() + 'images/spinner.gif" id="feedcheckspinner" />');
				$('#feed_feed_url_input').find('p.feed-check-info,p.inline-errors').remove();
			},
			complete: function(){
				$('#feedcheckspinner').remove();
			},
			success: function(json){
				var output = '';
				$('#feed_feed_url_input').append('<p class="feed-check-info"></p>');
				var items = new Array();
				$(json).each(function(){
					items.push(this.title);
				});
				items = items.slice(Math.max(items.length - 5, 1));
				$('#feed_feed_url_input p.feed-check-info').html('<span class="valid"></span><b>Looks good! The feed contains items like:</b> ' + items.join(', '));
			},
			error: function(){
				$('#feed_feed_url_input').append('<p class="inline-errors">It doesn\'t look like that\'s a valid feed. Please check the feed URL.');
			}
		});
	});
});
