var back_search, show_job, show_search_results;

$(document).bind("mobileinit", function() {
  return $.mobile.allowCrossDomainPages = true;
});

$(document).bind('pageinit', function() {
  return $('.search_btn').bind('click', function(e) {
    var loc, q;
    $.mobile.showPageLoadingMsg();
    $('#search_result').html("");
    $('#job_detail').html("");
    e.preventDefault();
    q = $.trim($('input[name="q"]').val());
    loc = $.trim($('input[name="loc"]').val());
    if (!(q.length || loc.length)) return false;
    console.log('submitting');
    return $.getJSON('http://api.findmjob.com/search?q=' + q + '&loc=' + loc + '&callback=?', function(data) {
      return show_search_results(data);
    });
  });
});

show_search_results = function(data) {
  var html, job, _i, _len, _ref;
  $(document).jqmData('jobs', data.jobs);
  $.mobile.hidePageLoadingMsg();
  html = '';
  _ref = data.jobs;
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    job = _ref[_i];
    html += "<li><a onclick=\"javascript: show_job('" + job.id + "')\" id='" + job.id + "'>" + job.title + "</a></li>";
  }
  return $('#search_result').html(html).listview("destroy").listview().show();
};

show_job = function(id) {
  var description, html, job, jobs, _i, _len, _results;
  $('#search_result').hide();
  jobs = $(document).jqmData('jobs');
  _results = [];
  for (_i = 0, _len = jobs.length; _i < _len; _i++) {
    job = jobs[_i];
    if (job.id === id) {
      description = job.description.replace("\n", "<br />");
      html = "<h3>" + job.title + "</h3>\n<p>" + job.description + "#</p>\n<input type='button' onclick=\"javascript:back_search()\" data-role=\"button\" value=\"Back to Search\" />";
      $('#job_detail').html(html);
      $('#job_detail').trigger('updatelayout');
      break;
    } else {
      _results.push(void 0);
    }
  }
  return _results;
};

back_search = function() {
  $('#search_result').show();
  return $('#job_detail').html("");
};
