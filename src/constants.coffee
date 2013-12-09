# Values that are required to be available to
# multiple parts of the application.
constants = exports

# The Accept headers that correspond to each data-type.
constants.ACCEPT_HEADER =
  'xml': 'application/xml'
  'json': 'application/json'
  'jsonobjects': 'application/json;type=objects'
  'jsontable': 'application/json;type=table'
  'jsonrows': 'application/json;type=rows'
  'jsoncount': 'application/json;type=count'
  'jsonp': 'application/javascript'
  'jsonpobjects': 'application/javascript;type=objects'
  'jsonptable': 'application/javascript;type=table'
  'jsonprows': 'application/javascript;type=rows'
  'jsonpcount': 'application/javascript;type=count'
