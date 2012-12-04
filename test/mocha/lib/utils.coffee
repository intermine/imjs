{Deferred} = require 'underscore.deferred'
{funcutils: {invoke}} = require './fixture'

exports.clear = (service, name) -> () -> Deferred ->
    service.fetchList(name).then(invoke 'del').always(@resolve)
