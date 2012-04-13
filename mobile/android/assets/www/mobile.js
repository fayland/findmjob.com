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
      console.log('xxxx');
      $('#debug').html('submitting');
      return $.ajax({
        url: 'http://api.findmjob.com/search',
        type: 'GET',
        dataType: 'json',
        timeout: 5000,
        data: {
          q: q,
          loc: loc
        },
        success: function(data) {
          var job, _i, _len, _ref, _results;
          $('#search_result').empty();
          _ref = data.jobs;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            job = _ref[_i];
            _results.push($('#search_result').append("<p><a class='job' id='" + job.id + "' data-role=\"button\">" + job.title + "</a></p>"));
          }
          return _results;
        },
        error: function(xhr, ajaxOptions, thrownError) {
          console.log(xhr.statusText);
          return $('#debug').html('failed');
        }
      });
    });
    return this;
  });

  this;

}).call(this);
