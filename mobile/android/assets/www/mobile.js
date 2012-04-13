(function() {

  $(document).bind("mobileinit", function() {
    return $.mobile.allowCrossDomainPages = true;
  });

  $(document).ready(function() {
    $('#debug').html('start');
    $('#search_btn').bind('click', function(e) {
      var loc, q;
      e.preventDefault();
      $('#debug').html('onclick');
      q = $.trim($('input[name="q"]').val());
      loc = $.trim($('input[name="loc"]').val());
      $('#debug').html(q);
      $('#debug').html(loc);
      if (!(q.length || loc.length)) return false;
      $('#debug').html('submitting');
      return $.ajax({
        url: 'http://api.findmjob.com/search',
        type: 'POST',
        dataType: 'jsonp',
        data: {
          q: q,
          loc: loc
        },
        success: function(response) {
          return $('#debug').html(response);
        },
        error: function(xhr, ajaxOptions, thrownError) {
          return $('#debug').html('failed');
        }
      });
    });
    return this;
  });

  this;

}).call(this);
