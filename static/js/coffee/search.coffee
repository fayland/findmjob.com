$(document).ready ->
    ## timeago
    $('.timeago').timeago();

    $('#search').submit ->
        q = $(this).find('input[name="q"]').val();
        return false unless q.length
        if /^\w+$/.test(q)
            $(this).attr('action', '/search/' + q + '.html')
        true