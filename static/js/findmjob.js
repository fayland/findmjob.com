(function() {

  $(document).ready(function() {
    $.timeago.settings.allowFuture = true;
    $('.timeago').timeago();
    return $('.search-form').submit(function() {
      var q;
      q = $(this).find('input[name="q"]').val();
      if (!q.length) return false;
      if (/^\w+$/.test(q)) $(this).attr('action', '/search/' + q + '.html');
      return true;
    });
  });

}).call(this);
