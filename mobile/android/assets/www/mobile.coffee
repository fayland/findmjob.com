$(document).bind "mobileinit", () ->
    console.log 'mobileinit'
    ## Make your jQuery Mobile framework configuration changes here!
    $.mobile.allowCrossDomainPages = true

$(document).bind 'pageinit', () ->
    ## for search
    $('.search_btn').bind 'click', (e) ->
        $('#search_loading').show()
        $('#search_result').html("")

        e.preventDefault()
        q = $.trim $('input[name="q"]').val()
        loc = $.trim $('input[name="loc"]').val()
        console.log q
        console.log loc
        return false unless q.length or loc.length
        console.log 'submitting'
        $.getJSON 'http://api.findmjob.com/search?q=' + q + '&loc=' + loc + '&callback=?', (data) ->
            show_search_results(data)

@

show_search_results = (data) ->
    console.log data
    $('#search_loading').hide()
    html = ''
    for job in data.jobs
        html += """<li><a class='job' id='#{job.id}' data-role="button">#{job.title}</a></li>"""
    $('#search_result').html(html).listview("destroy").listview()
