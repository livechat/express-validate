_ = require 'underscore'
validator = require './validator'

validatorWrapper = (opts) ->
	opts = opts or {}
	_.defaults opts, 
		exposeMixedParams: no
		rules: []
		errorParser: null
	
	for rule in opts.rules
		validator.addRule rule.name, rule.rule
	
	validatorMiddleware = (req, res, next) ->
		params = _.extend req.params || {}, req.query || {}, req.body || {}
		
		if opts.exposeMixedParams
			req.p = params
		
		req.validate = (rules) ->
			result = validator.validate params, rules
			
			if result.length and not opts.errorParser
				res.send result.join('\n'), 400
			else if result and opts.errorParser and typeof opts.errorParser == 'function'
				opts.errorParser req, res, result
			else if result and opts.errorParser
				throw new TypeError 'errorParser must be a function'
		
		next()
	
	# expose the public API
	return validatorMiddleware

module.exports = validatorWrapper