$(document).bind "mobileinit", () ->
    ## Make your jQuery Mobile framework configuration changes here!
    $.mobile.allowCrossDomainPages = true;

    ## for search
    $('#search_btn').bind 'click', (e) ->
        q = $.trim $(this).find('input[name="q"]').val()
        loc = $.trim $(this).find('input[name="loc"]').val()
        return false unless q.length or loc.length
        alert 'submitting'
        $.getJSON "http://api.findmjob.com/search?q=" + q + "loc=" + loc, (data) ->
            alert '1'
            alert data
    @
@