(function() {
  var show_search_results;

  $(document).bind("mobileinit", function() {
    console.log('mobileinit');
    return $.mobile.allowCrossDomainPages = true;
  });

  $(document).bind('pageinit', function() {
    return $('.search_btn').bind('click', function(e) {
      var loc, q;
      $('#search_loading').show();
      $('#search_result').html("");
      e.preventDefault();
      q = $.trim($('input[name="q"]').val());
      loc = $.trim($('input[name="loc"]').val());
      console.log(q);
      console.log(loc);
      if (!(q.length || loc.length)) return false;
      console.log('submitting');
      return $.getJSON('http://api.findmjob.com/search?q=' + q + '&loc=' + loc + '&callback=?', function(data) {
        return show_search_results(data);
      });
    });
  });

  this;

  show_search_results = function(data) {
    var html, job, _i, _len, _ref;
    console.log(data);
    $('#search_loading').hide();
    html = '';
    _ref = data.jobs;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      job = _ref[_i];
      html += "<li><a class='job' id='" + job.id + "' data-role=\"button\">" + job.title + "</a></li>";
    }
    return $('#search_result').html(html).listview("destroy").listview();
  };

}).call(this);
