var back_search, show_job, show_search_results;

$(document).bind('pageinit', function() {
  document.addEventListener("deviceready", function() {
    var networkState;
    networkState = navigator.network.connection.type;
    if (networkState === Connection.NONE) {
      return alert("You're offline now, please check your network");
    }
  });
  return $('.search_btn').bind('click', function(e) {
    var loc, q;
    $.mobile.showPageLoadingMsg();
    $('#search_result').html("");
    $('#job_detail').html("");
    e.preventDefault();
    q = $.trim($('input[name="q"]').val());
    loc = $.trim($('input[name="loc"]').val());
    if (!(q.length || loc.length)) return false;
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
      description = job.description.replace(/[\r\n]/g, "<br />");
      html = "<h2>" + job.title + "</h2>\n<div data-role=\"collapsible-set\">\n    <div data-role=\"collapsible\" data-content-theme=\"c\">\n    <h3>Attributes</h3>\n    <p><b>Posted</b>: " + job.posted_at + "</p>\n    <p><b>Company</b>: " + job.company.name + "</p>\n    <p><b>Location</b>: " + job.location + "</p>\n    <p><b>Tag</b>: " + (job.tag.join(', ')) + "</p>\n    <p><b>Hours</b>: " + job.type + "</p>\n    </div>\n    <div data-role=\"collapsible\" data-collapsed=\"false\" data-content-theme=\"c\">\n       <h3>Description</h3>\n       <p>" + description + "</p>\n    </div>\n    <div data-role=\"collapsible\" data-content-theme=\"c\">\n    <h3>Contact</h3>\n    <p>" + job.contact + "</p>\n    </div>\n</div>\n<input type='button' onclick=\"javascript:back_search()\" data-role=\"button\" value=\"Back to Search\" />";
      $('#job_detail').html(html);
      $('#job_detail input[data-role=button]').button();
      $('#job_detail div[data-role=collapsible]').collapsible();
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
