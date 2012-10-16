_ = require 'underscore'
validator = require './validator'

validatorWrapper = (opts) ->
	opts = opts or {}
	_.defaults opts, 
		exposeMixedParams: no
		rules: []
		asJSON: yes
	
	for rule in opts.rules
		validator.addRule rule.name, rule.rule
	
	validatorMiddleware = (req, res, next) ->
		
		req.validate = (rules) ->
			params = _.extend req.params || {}, req.query || {}, req.body || {}
			
			if opts.exposeMixedParams
				req.p = params
			
			result = validator.validate params, rules
			
			if result.length
				if opts.asJSON
					return {errors: result}
				else
					return result.join '\n'
			else
				return false
		
		next()
	
	# expose the public API
	return validatorMiddleware

module.exports = validatorWrapper