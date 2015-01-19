# Values that are required to be available to
# multiple parts of the application.

# The Accept headers that correspond to each data-type.
exports.ACCEPT_HEADER =
  'xml': 'application/xml'
  'json': 'application/json'
  'tsv': 'text/tab-separated-values'
  'tab': 'text/tab-separated-values'
  'csv': 'text/comma-separated-values'
  'fasta': 'text/x-fasta'
  'gff3': 'text/x-gff3'
  'bed': 'text/x-bed'
  'objects': 'application/json;type=objects'
  'jsonobjects': 'application/json;type=objects'
  'jsontable': 'application/json;type=table'
  'jsonrows': 'application/json;type=rows'
  'jsoncount': 'application/json;type=count'
  'jsonp': 'application/javascript'
  'jsonpobjects': 'application/javascript;type=objects'
  'jsonptable': 'application/javascript;type=table'
  'jsonprows': 'application/javascript;type=rows'
  'jsonpcount': 'application/javascript;type=count'
