$(document).bind "mobileinit", () ->
    ## Make your jQuery Mobile framework configuration changes here!
    $.mobile.allowCrossDomainPages = true

$(document).bind 'pageinit', () ->
    ## for search
    $('.search_btn').bind 'click', (e) ->
        $.mobile.showPageLoadingMsg()
        $('#search_result').html ""
        $('#job_detail').html ""

        e.preventDefault()
        q = $.trim $('input[name="q"]').val()
        loc = $.trim $('input[name="loc"]').val()
        return false unless q.length or loc.length
        console.log 'submitting'
        $.getJSON 'http://api.findmjob.com/search?q=' + q + '&loc=' + loc + '&callback=?', (data) ->
            show_search_results(data)

show_search_results = (data) ->
    $(document).jqmData('jobs', data.jobs)
    $.mobile.hidePageLoadingMsg()
    html = ''
    for job in data.jobs
        html += """
                <li><a onclick="javascript: show_job('#{job.id}')" id='#{job.id}'>#{job.title}</a></li>
                """
    $('#search_result').html(html).listview("destroy").listview().show()

show_job = (id) ->
    $('#search_result').hide()
    jobs = $(document).jqmData('jobs')
    for job in jobs
        if job.id == id
            description = job.description.replace("\n", "<br />")
            html = """
                    <h3>#{job.title}</h3>
                    <p>#{job.description}#</p>
                    <input type='button' onclick="javascript:back_search()" data-role="button" value="Back to Search" />
                   """
            $('#job_detail').html(html)
            ## $('#job_detail').trigger( 'updatelayout' );
            $('#job_detail input[data-role=button]').button()
            break

back_search = () ->
    $('#search_result').show()
    $('#job_detail').html ""
