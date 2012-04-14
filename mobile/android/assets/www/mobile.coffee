$(document).bind 'pageinit', () ->
    ## check network state
    document.addEventListener "deviceready", () ->
        networkState = navigator.network.connection.type;
        if networkState == Connection.NONE
            alert "You're offline now, please check your network"

    ## for search
    $('.search_btn').bind 'click', (e) ->
        $.mobile.showPageLoadingMsg()
        $('#search_result').html ""
        $('#job_detail').html ""

        e.preventDefault()
        q = $.trim $('input[name="q"]').val()
        loc = $.trim $('input[name="loc"]').val()
        return false unless q.length or loc.length
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
            description = job.description.replace(/[\r\n]/g, "<br />")
            html = """
                    <h2>#{job.title}</h2>
                    <div data-role="collapsible-set">
                        <div data-role="collapsible" data-content-theme="c">
                            <h3>Attributes</h3>
                            <p><b>Posted</b>: #{job.posted_at}</p>
                            <p><b>Company</b>: #{job.company.name}</p>
                            <p><b>Location</b>: #{job.location}</p>
                            <p><b>Tag</b>: #{job.tag.join(', ')}</p>
                            <p><b>Hours</b>: #{job.type}</p>
                        </div>
                        <div data-role="collapsible" data-collapsed="false" data-content-theme="c">
                           <h3>Description</h3>
                           <p>#{description}</p>
                        </div>
                        <div data-role="collapsible" data-content-theme="c">
                            <h3>Contact</h3>
                            <p>#{job.contact}</p>
                        </div>
                    </div>
                    <input type='button' onclick="javascript:back_search()" data-role="button" value="Back to Search Results" />
                   """
            $('#job_detail').html(html)
            $('#job_detail input[data-role=button]').button()
            $('#job_detail div[data-role=collapsible]').collapsible()
            break

back_search = () ->
    $('#search_result').show()
    $('#job_detail').html ""
