Plugin = require 'plugin'
Db = require 'db'

# Poll datastructure
# shared
#   polls
#       pollnumber
#           config
#               name => String
#               maxvotes => Int
#               anonymous => yes|no
#               customvalues => yes|no
#           values
#               value
#               ..
#           votes
#               valueId
#                   userid
#                   ..
#               ..
#       ..
exports.client_create = (data) !->
    maxId = Db.shared.modify 'maxId', (v) -> (v||0) + 1
    log "Creating poll", data, data.poll_name

    i = 0
    while (value = data['option'+i])?
        i++
        Db.shared.set "polls", maxId, "values", i, value

    Db.shared.set "polls", maxId, "config", "anonymous", data.poll_anonymous
    Db.shared.set "polls", maxId, "config", "customvalues", data.poll_custom_values
    Db.shared.set "polls", maxId, "config", "name", data.poll_name
    Db.shared.set "polls", maxId, "config", "owner", Plugin.userId()
    Db.shared.set "polls", maxId, "config", "maxvotes", data.poll_maxvotes
    Db.shared.set "polls", maxId, "open", true

exports.client_castvote = (pollId, valueId) !=>
    log "Voting in poll, with value:", pollId, valueId
    userId = Plugin.userId()
    poll = Db.shared.get "polls", pollId
    # log "Voting in poll", JSON.stringify(poll), poll['votes']?, poll['votes'][267]?, poll['votes'][userId]

    maxvalueId = 1
    if (votes = poll['votes'])?
        uservotes = []
        maxvotes = Db.shared.get "polls", pollId, "config", "maxvotes"
        numvotes = 0
        wasSelected = false
        log "Looping over", poll["votes"]
        for vid,uids of poll["votes"]
            log "Looping through voteIds, userIds", vid, uids
            if userId in uids
                uservotes.push vid
                numvotes++
                log "Comparing vid", vid, " to valueId", valueId
                if vid == valueId
                    wasSelected = true

        log "Uservotes:", JSON.stringify(uservotes)

        log "New maxvalueId", maxvalueId
        log "Numbers of votes cast so far", numvotes, "maximum number of votes", maxvotes

        if not valueVotes = Db.shared.get "polls", pollId, "votes", valueId
            valueVotes = []

        if wasSelected
            log "Was selected already, deselect"
            ind = valueVotes.indexOf(userId)
            valueVotes.splice(ind, 1)
            Db.shared.set "polls", pollId, "votes", valueId, valueVotes
        else
            if numvotes < maxvotes
                valueVotes.push userId
                Db.shared.set "polls", pollId, "votes", valueId, valueVotes
    else
        if valueVotes = Db.shared.get "polls", pollId, "votes", valueId
            valueVotes.push userId
        else
            valueVotes = [userId]
        Db.shared.set "polls", pollId, "votes", valueId, valueVotes
