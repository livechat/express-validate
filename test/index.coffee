express = require 'express'
validator = require '../lib/express-validate'

app = express.createServer()

app.use express.bodyParser()
app.use validator exposeMixedParams: true


app.get '/', (req, res) ->
	req.validate {
		name: { rule: 'required', message: '%s is required u A-HOLE!' }
		login: [{rule: 'required', message: '%s is required u A-HOLE2222!'}, 'email']
	}
	
	res.send "it's ok, dude"
	
	

app.listen 3000, () ->
	console.log "I'm listening."