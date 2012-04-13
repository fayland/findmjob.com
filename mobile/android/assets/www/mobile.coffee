$(document).bind "mobileinit", () ->
    ## Make your jQuery Mobile framework configuration changes here!
    $.mobile.allowCrossDomainPages = true

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
        console.log 'xxxx'
        $('#debug').html 'submitting'
        $.ajax {
            url: 'http://api.findmjob.com/search',
            type: 'GET',
            dataType: 'json',
            timeout: 5000,
            data: { q: q, loc: loc },
            success: (data) ->
                $('#search_result').empty();
                for job in data.jobs
                    $('#search_result').append """<p><a class='job' id='#{job.id}' data-role="button">#{job.title}</a></p>"""
            error: (xhr, ajaxOptions, thrownError) ->
                console.log xhr.statusText
                $('#debug').html 'failed'
        }
    @


@