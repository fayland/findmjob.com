$(document).bind "mobileinit", () ->
    ## Make your jQuery Mobile framework configuration changes here!
    $.mobile.allowCrossDomainPages = true;

$(document).ready ->
    $('#debug').html 'start'

    ## for search
    $('#search_btn').bind 'click', (e) ->
        e.preventDefault()
        $('#debug').html 'onclick'
        q = $.trim $('input[name="q"]').val()
        loc = $.trim $('input[name="loc"]').val()
        $('#debug').html q
        $('#debug').html loc
        return false unless q.length or loc.length
        $('#debug').html 'submitting'
        $.ajax {
            url: 'http://api.findmjob.com/search',
            type: 'POST',
            dataType: 'jsonp',
            data: { q: q, loc: loc },
            success: (response) ->
                $('#debug').html response
            error: (xhr, ajaxOptions, thrownError) ->
                $('#debug').html 'failed'
        }
    @
@