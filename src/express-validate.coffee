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
		
		req.defaults = (defaults) ->
			req.p = _.defaults req.p || {}, defaults
		
		req.validate = (rules) ->
			params = _.defaults req.p || {}, req.files, req.params, req.query, req.body
			
			if opts.exposeMixedParams
				req.p = params
			
			result = validator.validate params, rules
			
			if result.length
				if opts.asJSON
					res.send {errors: result}, 400
					return false
				else
					res.send result.join('\n'), 400
					return false
			else
				return true
		
		next()
	
	# expose the public API
	return validatorMiddleware

module.exports = validatorWrapper