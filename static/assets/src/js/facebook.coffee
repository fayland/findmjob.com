## facebook app
window.fbAsyncInit = () ->
    FB.init {
        appId : '281749461905114',
        status : true,
        cookie : true,
        xfbml : true
    }
    FB.Canvas.setAutoGrow();

e = document.createElement('script');
e.src = document.location.protocol + '//connect.facebook.net/en_US/all.js';
e.async = true;
document.getElementById('fb-root').appendChild(e);