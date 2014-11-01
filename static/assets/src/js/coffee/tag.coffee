$(document).ready ->
    $('a[fj-action="unfollow"]').click (e) ->
        e.preventDefault()
        e.stopPropagation()

        me = $(@)
        tag_id = me.attr('data-tag-id')
        $.getJSON '/user/unfollow', {'follow_id': tag_id}, (data) ->
            # do nothing
            me.parent('li').remove()