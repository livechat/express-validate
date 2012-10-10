Validator =
	rules: {}
	
	# given a name and a rule, add the rule to rules cache
	addRule: (name, rule) ->
		@rules[name] = rule
	
	# given the rule's name, return whether it's a valid rule 
	# (it has to have both test & message properties)
	checkRule: (name) ->
		rule = @rules[name]
		if typeof name == 'string' and rule and typeof rule.test == 'function' and typeof rule.message == 'string'
			return true
		
		throw new Error 'This is not a complete rule. A complete rule must contain both `test` function and `message` string.'
	
	# parses error messages
	# replaces %s with key name, $1, $2, …, with test function arguments
	error: (rule, key, customMessage) ->
		if customMessage
			return customMessage.replace(/%s/g, key)
		else
			return @rules[rule].message.replace(/%s/g, key)
	
	# perform the validation
	test: (obj, rule, key) ->
		if typeof rule == 'string'
			if @checkRule(rule) and @rules[rule].test(obj[key])
				return @error rule, key
		else
			if @checkRule(rule.rule) and @rules[rule.rule].test(obj[key])
				return @error rule.rule, key, rule.message
		
		return false
	
	validate: (obj, ruleset) ->
		for key, rule of ruleset
			# check if it's an array of rules
			if Array.isArray rule
				for nestedRule in rule
					testResult = @test obj, nestedRule, key
					return testResult if testResult
			
			# single rule
			else
				testResult = @test obj, rule, key
				return testResult if testResult 
		
		return false

Validator.addRule 'required',
	message: '%s is requried.'
	test: (str) ->
		return true unless str

Validator.addRule 'email',
	message: '%s must be a valid e-mail address.'
	regex: ///^
	([\w\!\#$\%\&\'\*\+\-\/\=\?\^\`{\|\}\~]+\.)*
	[\w\!\#$\%\&\'\*\+\-\/\=\?\^\`{\|\}\~]+
	@
	((((([a-z0-9]{1}[a-z0-9\-]{0,62}[a-z0-9]{1})|[a-z])\.)+[a-z]{2,6})|(\d{1,3}\.){3}\d{1,3}(\:\d{1,5})?)$
	///i
	test: (str) ->
		return !@regex.test str

Validator.addRule 'minLength',
	message: '%s must be at least %1 char long'
	test: (str, minLength) ->

module.exports = Validator