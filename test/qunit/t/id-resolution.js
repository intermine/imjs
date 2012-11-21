'use strict';

(function() {
    var get = intermine.funcutils.get,
        curry = intermine.funcutils.curry,
        invoke = intermine.funcutils.invoke,
        log = _.bind(console.log, console),
        shortList = ['Anne', 'Brenda', 'Carol'],
        longList = [
            'Anne', 'Brenda', 'Carol', 'David*',
            'Foo', 'Bar', 'Neil*', '*Godwin', 'Norbert',
            'Laverne Delillo', 'Lura Bal', 'Everette Shelor',
            'Ignacia Pickney', 'Maurita Donohue', 'Tomika Aucoin',
            'Jona Lent', 'Consuela Decarlo', 'Tonja Lorance',
            'Giovanni Robicheaux', 'Arlena Iannuzzi', 'Sherise Southwood',
            'Shonna Jerkins', 'Edwina Weick', 'Vilma Gines',
            'Abram Clever', 'Leatrice Mari', 'Milford Reddell',
            'Lonna Shawn', 'Khadijah Castelli', 'Florida Mcbay',
            'Wendy Lange', 'Margorie Mascarenas', 'Yen Hoelscher',
            'Erich Rodrigues', 'Judith Moller', 'Marcene Drayton',
            'Tamika Brunk', 'Vita Breton', 'Lanora Grider',
            'Amina Sharer', 'Dori Behr', 'Meagan Henton',
            'Mora Mckane', 'Sol Link', 'Shirlene Orosco',
            'Jacquelyne Wei', 'Madeline Macgregor', 'Steve Orum',
            'Belle Polo', 'Rubie Seabaugh', 'Wynell Seeley',
            'Patsy Speight', 'Charles Rost', 'Moira Tutson',
            'Marleen Moynihan', 'Marilu Kellogg', 'Su Fredericks',
            'Elliott Primer', 'Delisa Neider',
            'Enda', 'Joycelyn', 'Torri', 'Britni', 'Roberto',
            'Rosena', 'Matha', 'Machelle', 'Marybelle', 'Stasia',
            'Odelia', 'Bret', 'Marketta', 'Lacie', 'Tyrone',
            'Darrick', 'Zora', 'Berniece', 'Fran', 'Refugio',
            'Thao', 'Mose', 'Ciara', 'Jenine', 'Arlette', 'Sheryl',
            'Renae', 'Alex', 'Ampersand &', 'Andreas Hermann', 'Andy Bernard',
            'Angela', 'Anne', 'Bernard Giraud', 'Bernd Stromberg',
            'Berthold Heisterkamp', 'Brenda', 'Burkhardt Wutke', 'Carol',
            'Charles Miner', 'Claude Gautier', 'Comma , here', 'Corinne',
            'Dan Gore', 'David Brent', 'Delphine', 'Devon White',
            'Didier Leguélec', 'Double forward Slash //', 'Dr. Stefan Heinemann', 'Dwight Schrute',
            'Ed Truck', 'Emmanuelle', 'EmployeeA1', 'EmployeeA2',
            'EmployeeA3', 'EmployeeB1', 'EmployeeB2', 'EmployeeB3',
            'Erika Burstedt', 'Fabienne de Dos', 'Fatou', 'Forward Slash /',
            'Frank Möllers', 'Frank Montenbruck', 'Gabe Lewis', 'Gareth Keenan',
            'Gilles Triquet', 'Glynn Williams', 'Hans Georg Althoff', 'Hans Schmelzer',
            'Helena', 'Herr Fritsche', 'Herr Grahms', 'Herr Hilpers',
            'Herr Kitter', 'Herr Pötsch', 'Hidetoshi Takinawa', 'Ina',
            'Jacques Plagnol Jacques', 'Jean-Marc', 'Jennifer', 'Jennifer Schirrmann',
            'Jennifer Taylor-Clarke', 'Jerry DiCanio', 'Jim Halpert', 'Jo Bennet',
            'Jochen Schüler', 'Joel Liotard', 'Josef Müller', 'Josh Porter',
            'Juliette Lebrac', 'Kai Dörfler', 'Karim', 'Keith Bishop',
            'Kevin Malone', 'Lars Lehnhoff', 'Lee', 'Left Angle Bracket <',
            'Lonnis Collins', 'Madge Madsen', 'Magdalena Prellwitz', 'Maja Decker',
            'Malcolm', 'Marie-Claude', 'Matt', 'Meredith Palmer',
            'Michael', 'Michael Scott', 'Nadège', 'Nathan',
            'Neil Godwin', 'New line', 'here', 'Nicole', 'Nicole Rückert',
        ];

    module('ID-Resolution', TestCase);

    asyncTest('Resolve some ids', 1, function() {
        var onSuccess = _.compose(start, curry(equal, 3), get('length'), _.keys),
            onError = _.compose(start, log),
            onProgress = log;
        this.s.resolveIds({identifiers: shortList, type: 'Employee'})
            .then(invoke('poll', onSuccess, onError, onProgress));
    });

    asyncTest('Resolve some ids - promises', 1, function() {
        var onSuccess = _.compose(start, curry(equal, 3), get('length'), _.keys),
            onError = _.compose(start, log),
            onProgress = log;
        var job = this.s.resolveIds({identifiers: shortList, type: 'Employee'})
                      .then(invoke('poll'));
        job.done(onSuccess);
        job.fail(onError);
        job.progress(onProgress);
    });

    asyncTest('Resolve a longer list', 1, function() {
        var onSuccess = _.compose(start, curry(equal, 87), get('length'), _.keys),
            onError = _.compose(start, log),
            onProgress = log;
        this.s.resolveIds({identifiers: longList, type: 'Employee'})
            .then(invoke('poll', onSuccess, onError, onProgress));
    });
})();
