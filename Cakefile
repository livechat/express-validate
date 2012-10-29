fs = require 'fs'

{spawn} = require 'child_process'

task 'build', "Build CoffeeScript source files", ->
	coffee = spawn 'coffee', ['-cb', '-o', 'lib', 'src']
	coffee.stderr.on 'data', (data) -> console.log data.toString()
	coffee.stdout.on 'data', (data) -> console.log data.toString()
	
	index = spawn 'coffee', ['-cb', 'index.coffee']
	index.stderr.on 'data', (data) -> console.log data.toString()
	index.stdout.on 'data', (data) -> console.log data.toString()