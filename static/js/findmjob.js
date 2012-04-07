(function() {

  $(document).ready(function() {
    $('.timeago').timeago();
    return $('#search').submit(function() {
      var q;
      q = $(this).find('input[name="q"]').val();
      if (!q.length) return false;
      if (/^\w+$/.test(q)) $(this).attr('action', '/search/' + q + '.html');
      return true;
    });
  });

}).call(this);
