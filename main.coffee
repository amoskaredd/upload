fs = require 'fs'
os = require 'os'
bytes = require 'bytes'
express = require 'express'
{ fromBuffer } = require 'file-type'

limitSize = '500mb'
tmpFolder = os.tmpdir()

isBase64 = (str) ->
	try
		btoa(atob(str)) is str
	catch
		false

app = express()
app.set 'json spaces', 4
# limit upload file
app.use express.json limit: limitSize
app.use express.urlencoded extended: true, limit: limitSize
# logger
app.use (req, res, next) ->
	time = new Date().toLocaleString 'id', timeZone: 'Asia/Jakarta'
	console.log "[#{time}] #{req.method}: #{req.url}"
	next()
# allow user to access file in tmpFolder
app.use '/file', express.static tmpFolder

app.all '/', (_, res) -> res.send 'POST /upload'

app.all '/upload', (req, res) ->
	if req.method isnt 'POST'
		res.json message: 'Method not allowed'

	{ file } = req.body
	if not file and typeof file isnt 'string' and not isBase64 file
		res.json message: 'Payload body file must be filled in base64 format'

	fileBuffer = Buffer.from file, 'base64'
	ftype = await fromBuffer fileBuffer
	if not ftype then ftype = mime: 'file', ext: 'bin'
	
	randomName = Math.random().toString(36).slice(2)
	fileName = "#{ftype.mime.split('/')[0]}-#{randomName}.#{ftype.ext}"
	await fs.promises.writeFile "#{tmpFolder}/#{fileName}", fileBuffer
		
	res.json
		name: fileName,
		size:
			bytes: fileBuffer.length,
			readable: bytes fileBuffer.length, unitSeparator: ' '
		,
		type: ftype,
		url: "https://#{process.env.SPACE_HOST}/file/#{fileName}"

app.listen 7860, () -> console.log 'App running on port', 7860