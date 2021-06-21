express = require 'express'
validator = require '../lib/express-validate'

app = express()
app.use express.json()
app.use validator { exposeMixedParams: true }

app.get '/', (req, res) ->
	req.parse
		number: 'integer'

	req.validate {
		name: { rule: 'required', message: '%s is required u A-HOLE!' }
		login: [{ rule: 'required', message: '%s is required u A-HOLE2222!' }, 'email', { rule: 'minLength', minLength: 10 }]
		number: [{ rule: 'integer', message: 'Numbers muthaf-er, do you speak it?!' }, { rule: 'between', low: 10, high: 20 }]
	}

	res.send "it's ok, dude"

app.listen 3000, () ->
	console.log "I'm listening."