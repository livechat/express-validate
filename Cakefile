fs = require 'fs'

{spawn} = require 'child_process'

runProcess = (command, args, callback) ->
	proc = spawn command, args

	proc.stdout.pipe process.stdout, end: false
	proc.stderr.pipe process.stderr, end: false

	proc.on 'exit', callback

getProcessData = (command, args, callback) ->
	proc = spawn command, args

	stdout = ''
	stderr = ''

	proc.stdout.addListener 'data', getData = (chunk) ->
		stdout += chunk.toString()

	proc.stderr.addListener 'error', getError = (chunk) ->
		stderr += chunk.toString()

	proc.on 'exit', ->
		if stderr is '' then stderr = null
		callback stderr, stdout

task 'build', "Build CoffeeScript source files", ->
	coffee = spawn 'coffee', ['-cb', '-o', 'lib', 'src']
	coffee.stderr.on 'data', (data) -> console.log data.toString()
	coffee.stdout.on 'data', (data) -> console.log data.toString()
	
	index = spawn 'coffee', ['-cb', 'index.coffee']
	index.stderr.on 'data', (data) -> console.log data.toString()
	index.stdout.on 'data', (data) -> console.log data.toString()

task 'test', 'run unit tests', ->
	dir = fs.readdirSync 'test'
	args = []
	while dir.length
		args.push "test/#{dir.pop()}"

		args = args.concat ['-r','coffee-script/register','--ignore-leaks', '--colors','--reporter', 'spec']

		runProcess 'mocha', args, (exitCode) ->
			process.exit exitCode