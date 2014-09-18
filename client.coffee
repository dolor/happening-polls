Db = require 'db'
Dom = require 'dom'
Plugin = require 'plugin'
Page = require 'page'
Server = require 'server'
Ui = require 'ui'
Obs = require 'obs'
Form = require 'form'
{tr} = require 'i18n'

exports.render = !->

    if Page.state.get(0) is 'create'
        numfields = Obs.create 2

        Dom.h2 "Create Poll"
        Dom.section !->
            Dom.h3 "Poll Settings"
            Form.input
                value: ''
                name: 'poll_name'
                text: 'Name'
            Form.input
                value: 1
                name: 'poll_maxvotes'
                text: 'Maximum votes'
            Dom.div !->
                Dom.text tr("Enter 0 for no limit on votes")
                Dom.style {'font-style': 'italic', 'color': '#888'}
            Form.check
                name: 'poll_anonymous'
                text: 'Anonymous voting'
            Form.check
                name: 'poll_custom_values'
                text: 'Allow creating options'
        Dom.section !->
            Dom.h3 numfields.get() + " Poll Options"

            for i in [0...numfields.get()]
                Form.input
                    value: ''
                    text: 'Option ' + i
                    name: 'option' + i
            
            Ui.bigButton 'Add option', !->
                numfields.set(numfields.get() + 1)
            Ui.bigButton 'Remove last option', !->
                numfields.set(Math.max(numfields.get() - 1, 0))

        Form.setPageSubmit (data) !->
            Server.call 'create', data
            Page.back()

    else if pollId = Page.state.get(0)
        poll = Db.shared.ref("polls", pollId)
        config = poll.get("config")
        values = poll.get("values")
        Dom.h2 config.name

        selected = []
        for valueId, userIds of poll.get("votes")
            if Plugin.userId() in userIds
                selected.push valueId

        log "Selected", selected

        poll.iterate 'values', (value) !->
            Dom.section !->
                vid = value.key()
                if vid in selected
                    Dom.style {"background-color": "lightgray", "color": "green"}
                log "Valueid:", vid

                Dom.div !->
                    Dom.style _boxFlex: 1
                    castvotes = poll.get("votes")[vid]
                    votecount = castvotes.length
                    Dom.text "(" + votecount + ") " + value.get()

                Dom.div !->
                    Dom.style display: 'inline-block'
                    for userId in poll.get("votes", vid)
                        Ui.avatar Plugin.userAvatar(userId), !->
                            Dom.style display: 'inline-block'

                Dom.onTap !->
                    Server.call 'castvote', pollId, vid
            
    else
        activePolls = []
        closedPolls = []
        if polls = Db.shared.ref("polls")
            polls.iterate (poll) !->
                log "Poll: "
                log poll
                if poll.get('open')
                    activePolls.push poll
                else
                    closedPolls.push poll

        Dom.h2 "Active Polls"
        for poll in activePolls
            Dom.section !->
                pid = poll.key()
                Dom.onTap !->
                    Page.nav pid
                Dom.text poll.get('config').name

        Ui.bigButton 'Create Poll', !->
            Page.nav 'create'

        Dom.h2 "Finished polls"
        for poll in closedPolls
            Dom.section !->
                pid = poll.key()
                Dom.onTap !->
                    Page.nav pid
                Dom.text poll.get('config').name
