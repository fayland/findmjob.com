$(document).ready ->
    ## timeago
    $.timeago.settings.allowFuture = true
    $('.timeago').timeago()

    $('#search_form').submit ->
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