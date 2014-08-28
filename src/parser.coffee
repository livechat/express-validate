_ = require 'underscore'

Parser =
	parsers: {}

	addParser: (name, rule) ->
		@parsers[name] = rule

	checkRule: (name) ->
		rule = @parsers[name]
		if typeof name == 'string' and rule and typeof rule.parse == 'function'
			return true

		throw new Error name + ' is not a complete rule. A complete rule must contain `parse` function.'

	parse: (obj, ruleset) ->
		unless obj then return obj
		for key, rule of ruleset
			if (value = obj[key])?
				obj[key] = @parsers[rule].parse value

		return obj

Parser.addParser 'binary',
	parse: (value) ->
		if /^(true|[1-9]+[0-9]*)$/i.test value then 1 else 0

module.exports = Parser