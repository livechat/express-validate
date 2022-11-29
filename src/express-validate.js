const _ = require("underscore");
const validator = require("./validator");
const parser = require("./parser");

const validatorWrapper = function (opts) {
  let p;
  opts = opts || {};
  _.defaults(opts, {
    exposeMixedParams: false,
    rules: [],
    parsers: [],
    asJSON: true,
  });

  for (let rule of Array.from(opts.rules)) {
    validator.addRule(rule.name, rule.rule);
  }

  for (p of Array.from(opts.parsers)) {
    parser.addParser(p.name, p.parser);
  }

  return function (req, res, next) {
    req.parse = function (ruleset) {
      req.files = parser.parse(req.files, ruleset);
      req.p = parser.parse(req.p, ruleset);
      req.query = parser.parse(req.query, ruleset);
      return (req.body = parser.parse(req.body, ruleset));
    };

    req.defaults = (defaults) => (req.p = _.defaults(req.p || {}, defaults));

    req.validate = function (rules) {
      const params = _.extend({}, req.p, req.files, req.params, req.query, req.body);

      if (opts.exposeMixedParams) {
        req.p = params;
      }

      const result = validator.validate(params, rules);

      if (result.length === 0) {
        return true;
      }

      if (opts.asJSON) {
        let response = { errors: result };
        if (req.query.post_message) {
          response.fromAPI = 1;
          const b64 = new Buffer(JSON.stringify(response)).toString("base64");
          response = `<script>window.parent.postMessage('${b64}','*')</script>`;
        }
        res.status(400).send(response);
      } else {
        res.status(400).send(result.join("\n"));
      }

      return false;
    };

    return next();
  };
};

module.exports = validatorWrapper;
