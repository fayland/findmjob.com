(function() {

  $(document).ready(function() {
    var e, in_fb_app;
    $.timeago.settings.allowFuture = true;
    $('.timeago').timeago();
    in_fb_app = $.cookie('in_fb_app');
    if ((in_fb_app != null) && in_fb_app(eq('yes'))) {
      window.fbAsyncInit = function() {
        FB.init({
          appId: '281749461905114',
          status: true,
          cookie: true,
          xfbml: true
        });
        return FB.Canvas.setAutoGrow();
      };
      e = document.createElement('script');
      e.src = document.location.protocol + '//connect.facebook.net/en_US/all.js';
      e.async = true;
      document.getElementById('fb-root').appendChild(e);
    }
    return $('.search-form').submit(function() {
      var loc, q;
      q = $.trim($(this).find('input[name="q"]').val());
      loc = $.trim($(this).find('input[name="loc"]').val());
      if (!(q.length || loc.length)) return false;
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

}).call(this);
