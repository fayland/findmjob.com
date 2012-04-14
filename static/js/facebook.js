(function() {

  $(document).ready(function() {
    var e;
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
    return document.getElementById('fb-root').appendChild(e);
  });

}).call(this);
