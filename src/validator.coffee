_ = require 'underscore'

_regexp =
	ruleName: /%s/g
	ruleKey: /%([a-zA-Z]{1}([a-zA-Z0-9\-_]{1,})?)/g

Validator =
	options:
		errorParser: null
	rules: {}

	# given a name and a rule, add the rule to rules cache
	addRule: (name, rule) ->
		@rules[name] = rule

	# given the rule's name, return whether it's a valid rule
	# (it has to have both test & message properties)
	checkRule: (name) ->
		rule = @rules[name]

		switch rule.recurrent
			when true
				if typeof name == 'string' and rule and typeof rule.test == 'function' and rule.ruleset
					return true
			else
				if typeof name == 'string' and rule and typeof rule.test == 'function' and typeof rule.message == 'string'
					return true

		throw new Error name + ' is not a complete rule. A complete rule must contain both `test` function and `message` string.'

	# parses error messages
	# replaces %s with key name, %argName with rule.argName
	error: (rule, key, message, ruleArgs) ->
		unless message
			# no custom message passed
			message = @rules[rule].message
		return message.
			replace(_regexp.ruleName, key).
			replace(_regexp.ruleKey, (whole, first) =>
				if ruleArgs[first]?
					return ruleArgs[first]
				else if @rules[rule][first]?
					return @rules[rule][first]
				return whole
			)

	# perform the validation
	testInternal: (obj, rule, key) ->
		theRule = rule

		unless typeof rule == 'string'
			theRule = rule.rule

		if @checkRule(theRule)
			# allow rules using other rules by appling @rules to `test` method context
			unless @rules[theRule].recurrent? then @rules[theRule].recurrent = false

			context = _.defaults @rules[theRule], @
			if theRule == 'required' or obj[key]?
				error = @rules[theRule].test.call context, obj[key], rule

				if @rules[theRule].recurrent
					if error.length
						message = @error theRule, key, rule.message, rule
						err = {}
						err[message] = error
						return err

				else if error is false
					return @error theRule, key, rule.message, rule

		return false

	validate: (obj, ruleset) ->
		errors = []
		if _.isString ruleset
			try
				ruleset = @rules[ruleset].ruleset
			catch e
				throw new Error "missing #{ruleset} validation rule"

		for key, rule of ruleset
			# check if it's an array of rules
			if Array.isArray rule
				for nestedRule in rule
					testResult = @testInternal obj, nestedRule, key
					errors.push testResult if testResult

			# single rule
			else
				testResult = @testInternal obj, rule, key
				errors.push testResult if testResult

		return errors if errors.length
		return []

Validator.addRule 'required',
	message: "%s is required"
	test: (str) ->
		return str?

Validator.addRule 'email',
	message: "%s must be a valid e-mail address"
	regex: ///^
	([\w\!\#$\%\&\'\*\+\-\/\=\?\^\`{\|\}\~]+\.)*
	[\w\!\#$\%\&\'\*\+\-\/\=\?\^\`{\|\}\~]+
	@
	((((([a-z0-9]{1}[a-z0-9\-]{0,62}[a-z0-9]{1})|[a-z0-9])\.)+[a-z]{2,32})|(\d{1,3}\.){3}\d{1,3}(\:\d{1,5})?)$
	///i
	test: (str) ->
		return @regex.test str

Validator.addRule 'lengthBetween',
	message: "%s must be between %low and %high characters long"
	low: 0
	high: 5
	test: (str, rule) ->
		return false unless typeof str == 'string'

		low = rule.low or @low
		high = rule.high or @high
		len = str.length

		return (low <= len <= high)

Validator.addRule 'minLength',
	message: "%s must be at least %minLength characters long"
	minLength: 1
	test: (str, rule) ->
		minLength = rule?.minLength or @minLength
		return @rules.lengthBetween.test str, {low: minLength, high: Infinity}

Validator.addRule 'maxLength',
	message: "%s must be at most %maxLength characters long"
	maxLength: 1
	test: (str, rule) ->
		maxLength = rule?.maxLength or @maxLength
		return @rules.lengthBetween.test str, {low: 0, high: maxLength}

Validator.addRule 'between',
	message: "%s must be between %low and %high"
	low: 0
	high: 0
	test: (str, rule) ->
		str = parseInt(str, 10)
		low = rule.low or @low
		high = rule.high or @high

		return (low <= str <= high)

Validator.addRule 'greaterThan',
	message: "%s must be greater than %than"
	than: 0
	test: (str, rule) ->
		than = rule.than or @than
		return @rules.between.test str, {low: than+1, high: Infinity}

Validator.addRule 'lowerThan',
	message: "%s must be lower than %than"
	than: 0
	test: (str, rule) ->
		than = rule.than or @than
		return @rules.between.test str, {low: -Infinity, high: than-1}

Validator.addRule 'nonNegative',
	message: "%s must be non-negative"
	test: (str) ->
		return @rules.between.test str, {low: -1, high: Infinity}

Validator.addRule 'positive',
	message: "%s must be positive"
	test: (str) ->
		return @rules.between.test str, {low: 1, high: Infinity}

Validator.addRule 'negative',
	message: "%s must be negative"
	test: (str) ->
		return @rules.between.test str, {low: -Infinity, high: -1}

Validator.addRule 'integer',
	message: "%s must be an integer"
	test: (str) ->
		return /^-?[0-9]+$/.test str

Validator.addRule 'match',
	message: "%s doesn't match the required pattern"
	pattern: /(.)*/
	test: (str, rule) ->
		pattern = rule.pattern or @pattern
		return str.match pattern

Validator.addRule 'equals',
	message: "%s isn't '%to'"
	to: ""
	test: (str, rule) ->
		to = rule.to or @to
		return str == to

Validator.addRule 'list',
	recurrent: true
	message: "invalid %s list"
	ruleset: 'required'
	test: (array, rule) ->
		errors = []
		ruleset = rule.ruleset || @ruleset

		for element, index in array
			error = @validate {element:element}, {element: ruleset}
			if error.length
				e = {}
				e[index] = error
				errors.push e

		return errors

Validator.addRule 'notEmpty',
	message: "%s can't be empty array"
	test: (obj) ->
		return not _.isEmpty obj

Validator.addRule 'array',
	message: "%s must be an array"
	test: (obj) ->
		return _.isArray obj

Validator.addRule 'binary',
	message: "%s must be either '0' or '1'"
	test: (str) ->
		unless str? then return false
		return str.toString() in ['0', '1']


Validator.addRule 'order',
	order: ['asc', 'desc']
	message: "%s must be either 'asc' or 'desc'"
	test: (order) ->
		return order in @order

Validator.addRule 'zipcode',
	message: "%s must be valid zip code format XX-XXX"
	test: (code) ->
		return /(^\d{3}-\d{2}$)/.test code

Validator.addRule 'deny',
	message: "%s is forbidden"
	test: ->
		return false

module.exports = Validator