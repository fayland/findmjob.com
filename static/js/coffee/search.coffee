$(document).ready ->
    ## timeago
    $.timeago.settings.allowFuture = true
    $('.timeago').timeago()

    ## facebook app
    in_fb_app = $.cookie('in_fb_app')
    if (in_fb_app? and in_fb_app == 'yes')
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

    $('.search-form').submit ->
        q = $.trim $(this).find('input[name="q"]').val()
        loc = $.trim $(this).find('input[name="loc"]').val()
        return false unless q.length or loc.length
        if /^\w+$/.test(q)
            if loc and /^\w+$/.test(loc)
                $(this).attr('action', '/search/' + q + '_in_' + loc + '.html')
            else
                $(this).attr('action', '/search/' + q + '.html')
        else
            if loc and /^\w+$/.test(loc)
                $(this).attr('action', '/search/in_' + loc + '.html')
        true