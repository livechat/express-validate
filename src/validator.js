const _ = require("underscore");

const _regexp = {
  ruleName: /%s/g,
  ruleKey: /%([a-zA-Z]([a-zA-Z0-9\-_]+)?)/g,
};

const Validator = {
  options: {
    errorParser: null,
  },
  rules: {},

  // given a name and a rule, add the rule to rules cache
  addRule(name, rule) {
    return (this.rules[name] = rule);
  },

  // given the rule's name, return whether it's a valid rule
  // (it has to have both test & message properties)
  checkRule(name) {
    const rule = this.rules[name];

    switch (rule.recurrent) {
      case true:
        if (typeof name === "string" && rule && rule.ruleset) {
          return true;
        }
        break;
      default:
        if (typeof name === "string" && rule && typeof rule.test === "function" && typeof rule.message === "string") {
          return true;
        }
    }

    throw new Error(
      name + " is not a complete rule. A complete rule must contain both `test` function and `message` string."
    );
  },

  // parses error messages
  // replaces %s with key name, %argName with rule.argName
  error(rule, key, message, ruleArgs) {
    if (!message) {
      // no custom message passed
      ({ message } = this.rules[rule]);
    }
    return message.replace(_regexp.ruleName, key).replace(_regexp.ruleKey, (whole, first) => {
      if (ruleArgs[first] != null) {
        return ruleArgs[first];
      } else if (this.rules[rule][first] != null) {
        return this.rules[rule][first];
      }
      return whole;
    });
  },

  // perform the validation
  testInternal(obj, rule, key) {
    let theRule = rule;

    if (typeof rule !== "string") {
      theRule = rule.rule;
    }

    if (this.checkRule(theRule)) {
      // allow rules using other rules by applying @rules to `test` method context
      if (this.rules[theRule].recurrent == null) {
        this.rules[theRule].recurrent = false;
      }

      const context = _.defaults(this.rules[theRule], this);
      if (theRule === "required" || obj[key] != null) {
        let error, message;
        if (this.rules[theRule].recurrent) {
          error = this.validate(obj[key], this.rules[theRule].ruleset);
          if (error.length) {
            message = this.error(theRule, key, rule.message, rule);
            const err = {};
            err[message] = error;
            return err;
          }
        } else {
          error = this.rules[theRule].test.call(context, obj[key], rule);
          if (error === false) {
            return this.error(theRule, key, rule.message, rule);
          }
        }
      }
    }

    return false;
  },

  validate(obj, ruleset) {
    const errors = [];
    if (_.isString(ruleset)) {
      try {
        ({ ruleset } = this.rules[ruleset]);
      } catch (e) {
        throw new Error(`missing ${ruleset} validation rule`);
      }
    }

    for (const key in ruleset) {
      // check if it's an array of rules
      let testResult;
      const rule = ruleset[key];
      if (Array.isArray(rule)) {
        for (const nestedRule of Array.from(rule)) {
          testResult = this.testInternal(obj, nestedRule, key);
          if (testResult) {
            errors.push(testResult);
          }
        }

        // single rule
      } else {
        testResult = this.testInternal(obj, rule, key);
        if (testResult) {
          errors.push(testResult);
        }
      }
    }

    if (errors.length) {
      return errors;
    }
    return [];
  },
};

Validator.addRule("required", {
  message: "%s is required",
  test(str) {
    return str != null;
  },
});

Validator.addRule("email", {
  message: "%s must be a valid e-mail address",
  maxLength: 254, // RFC 3696 with errata 246
  regex: new RegExp(
    "^\
(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*\
|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")\
@\
(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}\
(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)])\
",
    "i"
  ),
  test(str) {
    if (typeof str !== "string") {
      return false;
    }
    return str.length <= this.maxLength && this.regex.test(str);
  },
});

Validator.addRule("lengthBetween", {
  message: "%s must be between %low and %high characters long",
  low: 0,
  high: 5,
  test(str, rule) {
    if (typeof str !== "string" && !_.isArray(str)) {
      return false;
    }

    const low = rule.low || this.low;
    const high = rule.high || this.high;
    const len = str.length;

    return low <= len && len <= high;
  },
});

Validator.addRule("minLength", {
  message: "",
  minLength: 1,
  test(str, rule) {
    if (_.isArray(str)) {
      this.message = "%s must be at least %minLength elements long";
    } else {
      this.message = "%s must be at least %minLength characters long";
    }

    const minLength = (rule != null ? rule.minLength : undefined) || this.minLength;
    return this.rules.lengthBetween.test(str, { low: minLength, high: Infinity });
  },
});

Validator.addRule("maxLength", {
  message: "",
  maxLength: 1,
  test(str, rule) {
    if (_.isArray(str)) {
      this.message = "%s must be at most %maxLength elements long";
    } else {
      this.message = "%s must be at most %maxLength characters long";
    }

    const maxLength = (rule != null ? rule.maxLength : undefined) || this.maxLength;
    return this.rules.lengthBetween.test(str, { low: 0, high: maxLength });
  },
});

Validator.addRule("between", {
  message: "%s must be between %low and %high",
  low: 0,
  high: 0,
  test(str, rule) {
    str = parseInt(str, 10);
    const low = rule.low || this.low;
    const high = rule.high || this.high;

    return low <= str && str <= high;
  },
});

Validator.addRule("greaterThan", {
  message: "%s must be greater than %than",
  than: 0,
  test(str, rule) {
    const than = rule.than || this.than;
    return this.rules.between.test(str, { low: than + 1, high: Infinity });
  },
});

Validator.addRule("lowerThan", {
  message: "%s must be lower than %than",
  than: 0,
  test(str, rule) {
    const than = rule.than || this.than;
    return this.rules.between.test(str, { low: -Infinity, high: than - 1 });
  },
});

Validator.addRule("nonNegative", {
  message: "%s must be non-negative",
  test(str) {
    return this.rules.between.test(str, { low: 0, high: Infinity });
  },
});

Validator.addRule("positive", {
  message: "%s must be positive",
  test(str) {
    return this.rules.between.test(str, { low: 1, high: Infinity });
  },
});

Validator.addRule("negative", {
  message: "%s must be negative",
  test(str) {
    return this.rules.between.test(str, { low: -Infinity, high: -1 });
  },
});

Validator.addRule("integer", {
  message: "%s must be an integer",
  test(str) {
    return /^-?[0-9]+$/.test(str);
  },
});

Validator.addRule("match", {
  message: "%s doesn't match the required pattern",
  pattern: /(.)*/,
  test(str, rule) {
    const pattern = rule.pattern || this.pattern;
    return str.match(pattern);
  },
});

Validator.addRule("equals", {
  message: "%s isn't '%to'",
  to: "",
  test(str, rule) {
    const to = rule.to || this.to;
    return str === to;
  },
});

Validator.addRule("list", {
  message: "invalid %s list",
  ruleset: "required",
  test(array, rule) {
    const ruleset = rule.ruleset || this.ruleset;

    for (let index = 0; index < array.length; index++) {
      const element = array[index];
      const error = this.validate({ element }, { element: ruleset });
      if (error.length) {
        return false;
      }
    }

    return true;
  },
});

Validator.addRule("notEmpty", {
  message: "%s can't be empty array",
  test(obj) {
    return !_.isEmpty(obj);
  },
});

Validator.addRule("array", {
  message: "%s must be an array",
  test(obj) {
    return _.isArray(obj);
  },
});

Validator.addRule("binary", {
  message: "%s must be either '0' or '1'",
  test(str) {
    if (str == null) {
      return false;
    }

    return ["0", "1"].includes(str.toString());
  },
});

Validator.addRule("order", {
  order: ["asc", "desc"],
  message: "%s must be either 'asc' or 'desc'",
  test(order) {
    return Array.from(this.order).includes(order);
  },
});

Validator.addRule("zipcode", {
  message: "%s must be valid zip code format XX-XXX",
  test(code) {
    return /(^\d{3}-\d{2}$)/.test(code);
  },
});

Validator.addRule("deny", {
  message: "%s is forbidden",
  test() {
    return false;
  },
});

module.exports = Validator;
