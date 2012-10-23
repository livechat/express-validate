_ = require 'underscore'
validator = require './validator'

compactObject = (obj) ->
	for i of obj
		if obj.hasOwnProperty i
			if !obj[i] and typeof obj[i] != 'number'
				delete obj[i]
	
	return obj

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
			params = _.extend req.p || {}, compactObject(req.files), compactObject(req.params), compactObject(req.query), compactObject(req.body)
			
			if opts.exposeMixedParams
				req.p = params
			
			result = validator.validate params, rules
			
			if result.length
				res.responseCode = 400
				
				if opts.asJSON
					res.send {errors: result}
					return false
				else
					res.send result.join '\n'
					return false
			else
				return true
		
		next()
	
	# expose the public API
	return validatorMiddleware

module.exports = validatorWrapper