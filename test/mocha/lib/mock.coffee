nock = require 'nock'
path = require 'path'
fs   = require 'fs'
url  = require 'url'

TESTMODEL_URL_VAR = 'TESTMODEL_URL'
root = process.env[TESTMODEL_URL_VAR]

RESPONSE_FOLDER = 'responses'
META_FILE = '_meta.json'

# Helper function to record the nock responses and store them
# fileName (string) -> Where you want to store in the responses, 
#   ideally should end in 'json'
# before, after (function) -> before and after hooks of the Unit Test, to which
#   one needs to attatch the recorder to
recordResponses = (fileName, before, after) ->
    before ->
        nock.recorder.rec
            output_objects: true
    
    after ->
        nock.restore()
        nockCallObjects = nock.recorder.play()
        fs.writeFile fileName, JSON.stringify(nockCallObjects), console.error

parseUrl = (relativeUrl) ->
    urlObj = url.parse relativeUrl
    # pathname = urlObj.pathname?.slice 1      # Remove the leading '/'
    # querystring = urlObj.search?.slice 1     # Remove the leading '?'
    # fragment = urlObj.hash?.slice 1          # Remove the leading '#'
    pathname = urlObj.pathname
    querystring = urlObj.search
    fragment = urlObj.hash

    return 
        pathname: pathname
        querystring: querystring
        fragment: fragment



# Helper function to find the file storing the responses,
# along with the query parameter specified.
# url (string) -> Must be relative to the 'root', eg. '/service/model?format=json' is a valid 
#   part of the url, note the leading slash. Initial part of the path used will be 'root', i.e.
#   concatenation of 'root' and the 'url' must provide the path of the query to be resolved
findResponse = (url) ->
    parsedUrl = parseUrl url
    {pathname, querystring} = parsedUrl
    # Convert the pathname to the folder name by replacing '/' with OS specific delimiter
    folderName = path.join RESPONSE_FOLDER, pathname.split('/').join path.sep
    metaFileName = path.join folderName, META_FILE
    responsesData = JSON.parse fs.readFileSync metaFileName
    for k,v of responsesData
        if k is querystring
            console.log JSON.parse fs.readFileSync path.join folderName, v.file 

# nockTest = ->
    # nock 'http://localhost:8080/intermine-demo'
        # .get '/service/model'
        # .replyWithFile 200, path.join __dirname, 'responses/service-model.xml'


module.exports =
    # nockTest: nockTest
    recordResponses: recordResponses
    findResponse: findResponse