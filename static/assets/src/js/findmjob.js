(function() {
  $(document).ready(function() {
    $.timeago.settings.allowFuture = true;
    $('.timeago').timeago();
    return $('#search_form').submit(function() {
      var loc, q;
      q = $.trim($(this).find('input[name="q"]').val());
      loc = $.trim($(this).find('input[name="loc"]').val());
      if (!(q.length || loc.length)) {
        return false;
      }
      if (/^\w+$/.test(q)) {
        if (loc && /^\w+$/.test(loc)) {
          $(this).attr('action', '/search/' + q + '_in_' + loc + '.html');
        } else {
          $(this).attr('action', '/search/' + q + '.html');
        }
      } else {
        if (loc && /^\w+$/.test(loc)) {
          $(this).attr('action', '/search/in_' + loc + '.html');
        }
      }
      return true;
    });
  });

  $(document).ready(function() {
    return $('a[fj-action="unfollow"]').click(function(e) {
      var me, tag_id;
      e.preventDefault();
      e.stopPropagation();
      me = $(this);
      tag_id = me.attr('data-tag-id');
      return $.getJSON('/user/unfollow', {
        'follow_id': tag_id
      }, function(data) {
        return me.parent('li').remove();
      });
    });
  });

}).call(this);
