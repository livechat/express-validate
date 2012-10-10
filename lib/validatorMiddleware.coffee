_ = require 'underscore'
validator = require './validator'

validatorWrapper = (opts) ->
	_.defaults opts, 
		exposeMixedParams: no
	
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