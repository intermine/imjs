if (typeof intermine == "undefined") {
    intermine = {};
}
if (typeof __ == "undefined") {
    __ = function(x) {return _(x).chain()};
}

_.extend(intermine, (function() {
    var List = function(properties, service) {

        _(this).extend(properties);
        this.service = service;
        this.dateCreated = this.dateCreated ? new Date(this.dateCreated) : null;

        this.folders = __(this.tags).filter(function(t) {return t.substr(0, t.indexOf(":")) === '__folder__'})
                                    .map(function(t) {return t.substr(t.indexOf(":") + 1) })
                                    .value();

    };

    return {"List": List};
})());
        
