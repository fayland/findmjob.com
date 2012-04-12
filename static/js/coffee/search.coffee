$(document).ready ->
    ## timeago
    $.timeago.settings.allowFuture = true
    $('.timeago').timeago()

    $('.search-form').submit ->
        q = $.trim $(this).find('input[name="q"]').val()
        return false unless q.length
        if /^\w+$/.test(q)
            loc = $.trim $(this).find('input[name="loc"]').val()
            if loc and /^\w+$/.test(loc)
                $(this).attr('action', '/search/' + q + '_in_' + loc + '.html')
            else
                $(this).attr('action', '/search/' + q + '.html')
        true