# express-validate

A very simple Express middleware to… well, validate stuff.

## Available validators

- required
- email
- equals
- lengthBetween
- maxLength
- minLength
- between
- greaterThan
- lowerThan
- nonNegative
- positive
- negative
- match
- ...write your your own!

## Options

```
var validator = require("../src/express-validate");
app.use(validator(options));
```

`options` is an object with possible properties:

- `rules` - (_object_) - additional rules (described later)
- `errorParser` - (_function_) - a function taking 3 arguments: `req`, `res` and `errors` (an array of error messages). If validation resulted in no errors, `errors` will be an empty array.

  example usage - returning JSON object

  ```
  errorParser: function(req, res, err) {
    return res.send({
      errors: err
    });
  }
  ```

- `exposeMixedParams` - (_bool_) - if `true`, `req.p` will become an object containing params available in `req.params`, `req.query` and `req.body`.

## Usage examples

### Basic validation

Server code:

```
var express = require("express");
var validator = require("../src/express-validate");

var app = express();
app.use(express.json());
app.use(validator());

app.get("/", function(req, res) {
    req.validate({
        name: "required", // single validation rule
        mail: [
            "required",
            "email" // or an array of rules
        ]
    });
    return res.send("it's ok");
});

app.listen(3000, function() {
    return console.log("Listening on 3000...");
});
```

Requests:

```
~ ➢ curl "localhost:3000"
name is requried.
~ ➢ curl localhost:3000/?name=maciej
mail is requried.
~ ➢ curl "localhost:3000/?name=maciek&mail=me@mpawlowski.pl"
it's ok

```

### Customizing error messages

Validation code:

```
req.validate({
    name: {rule: "required", message: "%s is required!"},
    age: ["required", {
        rule: "greaterThan",
        than: 18,
        message: "Hey, you must be over %than to see the content. Please, provide the correct %s",
    }]
})
```

Requests:

```
~ ➢ curl "localhost:3000/?name=maciej"
age is requried.
~ ➢ curl "localhost:3000/?name=maciej&age=17"
Hey, you must be over 18 to see the content. Please, provide the correct age
~ ➢ curl "localhost:3000/?name=maciej&age=24"
it's ok
```

### Adding custom rules

Server code:

```
var express = require("express");
var validator = require("../src/express-validate");

var app = express();
app.use(express.json());
app.use(validator({
    rules: [
        {
            name: "FOO",
            rule: {
                message: "%s must equal FOO",
                test: function(str) {
                    if (!str) {
                        return false; // it's not required
                    }
                    if (str !== "FOO") {
                        return true;
                    }
                }
            }
        },
        {
            name: "lengthBetween",
            rule: {
                message: "%s must be between %low and %high characters long",
                low: 3,
                high: 5,
                test: function(str, rule) {
                    var high, len, low;
                    if (!str) {
                        return false;
                    }
                    if (typeof str !== "string") {
                        return true;
                    }
                    low = rule.low || this.low;
                    high = rule.high || this.high;
                    len = str.length;
                    if (!((low <= len && len <= high))) {
                        return true;
                    }
                }
            }
        }
    ]
}));

app.get("/", function(req, res) {
    req.validate({
        foo: "FOO",
        str: {
            rule: "lengthBetween",
            low: 4,
            high: 7
        }
    });
    return res.send("it's ok");
});

app.listen(3000, function() {
    return console.log("Listening on 3000...");
});

```

Requests:

```
~ ➢ curl "localhost:3000/?foo=1"
foo must equal FOO
~ ➢ curl "localhost:3000/?foo=FOO"
it's ok
~ ➢ curl "localhost:3000/?str=mp"
str must be between 4 and 7 characters long
~ ➢ curl "localhost:3000/?str=1234"
it's ok
~ ➢ curl "localhost:3000/?str=12345678"
str must be between 4 and 7 characters long
```

## License

_(The MIT License)_

Copyright (c) 2012 Maciej Pawłowski <me@mpawlowski.pl>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
