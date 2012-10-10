_ = require 'underscore'
validator = require './validator'

validatorWrapper = (opts) ->
	_.defaults opts, 
		exposeMixedParams: no
	
	validatorMiddleware = (req, res, next) ->
		
		req.validate = (rules) ->
			result = validator.validate req.query, rules
			
			if result
				res.send result, 400
		
		next()
	
	# expose the public API
	return validatorMiddleware

module.exports = validatorWrapper