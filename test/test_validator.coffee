_ = require 'underscore'
sinon = require 'sinon'
should = require 'should'
validator = require '../src/validator'

describe "Validator", ()->

	describe "rules", ->
		it "required rule", () ->
			validator.testInternal({key: 5}, "required", "key").should.be.false
			validator.testInternal({key: {}}, "required", "key").should.be.false
			validator.testInternal({key: []}, "required", "key").should.be.false

			validator.testInternal({key: null}, "required", "key").should.not.be.false
			validator.testInternal({}, "required", "key").should.not.be.false

		it "max length rule", () ->
			validator.testInternal({key: "ads"}, "maxLength", "key").should.not.be.false
			validator.testInternal({key: "ads"}, {rule: "maxLength", maxLength:20}, "key").should.be.false

		it "integer rule", () ->
			validator.testInternal({key: "ads"}, "integer", "key").should.not.be.false
			validator.testInternal({key: []}, "integer", "key").should.not.be.false
			validator.testInternal({key: {}}, "integer", "key").should.not.be.false
			validator.testInternal({key: 5.2}, "integer", "key").should.not.be.false
			validator.testInternal({key: -5.2}, "integer", "key").should.not.be.false
			validator.testInternal({key: NaN}, "integer", "key").should.not.be.false
			validator.testInternal({key: -Infinity}, "integer", "key").should.not.be.false
			validator.testInternal({key: Infinity}, "integer", "key").should.not.be.false

			validator.testInternal({key: 0}, "integer", "key").should.be.false
			validator.testInternal({key: 1}, "integer", "key").should.be.false
			validator.testInternal({key: -1}, "integer", "key").should.be.false
			validator.testInternal({key: "-1"}, "integer", "key").should.be.false
			validator.testInternal({key: "1"}, "integer", "key").should.be.false
			validator.testInternal({key: "0"}, "integer", "key").should.be.false

	describe "validate", ->
		it "should validate simple object", () ->
			validator.validate({key: "value"}, {key: "required"}).length.should.equal 0
			validator.validate({key: "value"}, {key: ["required"]}).length.should.equal 0

			validator.validate({key: "value"}, {key: ["required", "maxLength"]}).length.should.equal 1
			validator.validate({key: "value"}, {key: ["required", {rule: "maxLength", maxLength: 30}]}).length.should.equal 0

		it "should validate recurrent object", () ->

			validator.addRule "book",
				recurrent: true
				message: "invalid book's properties"
				ruleset:
					author: ['required', {rule: "maxLength", maxLength: 30}]
					pages: ['integer']

				test: (agent) ->
					return @validate agent, @ruleset

			validator.validate({book: {author: "Steven King"}}, {book: 'book'}).length.should.equal 0
			validator.validate({book: {author: "Steven King, Steven King, Steven King, Steven King"}}, {book: 'book'}).length.should.equal 1
			validator.validate({book: {pages: 30}}, {book: 'book'}).length.should.equal 1
			validator.validate({book: {pages: -123.3}}, {book: 'book'}).length.should.equal 1

		it "should validate root properties", () ->
			validator.addRule "book",
				recurrent: true
				message: "invalid book's properties"
				ruleset:
					author: ['required', {rule: "maxLength", maxLength: 30}]
					pages: ['integer']

				test: (agent) ->
					return @validate agent, @ruleset

			validator.validate({author: "Steven King"}, 'book').length.should.equal 0
			validator.validate({pages: -123.2}, 'book').length.should.equal 2

		it "should validate lists", () ->
			validator.validate({integers: [1,2,3.2,4.3,5]}, {integers: {rule: 'list', ruleset: 'integer'}}).length.should.equal 1
			validator.validate({integers: [1,2,5]}, {integers: {rule: 'list', ruleset: 'integer'}}).length.should.equal 0

		it "should validate compound object", () ->

			validator.addRule "book",
				recurrent: true
				message: "invalid book's properties"
				ruleset:
					author: ['required', {rule: "maxLength", maxLength: 30}]
					pages: {rule: 'list', ruleset: 'integer'}

			validator.validate({pages: [12, 123.6], author: 'Steven'}, 'book').length.should.be.equal 1
			validator.validate({pages: [12], author: 'Steven'}, 'book').length.should.be.equal 0

		it "should crash when rule is not found", () ->
			f = -> validator.validate({asdf:5}, 'missingRule')
			f.should.throw()

			f = -> validator.validate({asdf:5}, 'required')
			f.should.not.throw()

			f = -> validator.validate({asdf:5}, {asdf: [{rule:'list', ruleset: 'integer'}]})
			f.should.not.throw()
