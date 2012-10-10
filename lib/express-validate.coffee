_ = require 'underscore'
validator = require './validator'

validatorWrapper = (opts) ->
	opts = opts or {}
	_.defaults opts, 
		exposeMixedParams: no
		rules: []
	
	for rule in opts.rules
		validator.addRule rule.name, rule.rule
	
	validatorMiddleware = (req, res, next) ->
		params = _.extend req.params || {}, req.query || {}, req.body || {}
		
		if opts.exposeMixedParams
			req.p = params
		
		req.validate = (rules) ->
			result = validator.validate params, rules
			
			if result
				res.send result, 400
		
		next()
	
	# expose the public API
	return validatorMiddleware

module.exports = validatorWrapper