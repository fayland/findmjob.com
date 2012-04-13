(function() {

  $(document).bind("mobileinit", function() {
    $.mobile.allowCrossDomainPages = true;
    $('#search_btn').bind('click', function(e) {
      var loc, q;
      q = $.trim($(this).find('input[name="q"]').val());
      loc = $.trim($(this).find('input[name="loc"]').val());
      if (!(q.length || loc.length)) return false;
      alert('submitting');
      return $.getJSON("http://api.findmjob.com/search?q=" + q + "loc=" + loc, function(data) {
        alert('1');
        return alert(data);
      });
    });
    return this;
  });

  this;

}).call(this);
