const Parser = {
  parsers: {},

  addParser(name, rule) {
    return (this.parsers[name] = rule);
  },

  checkRule(name) {
    const rule = this.parsers[name];
    if (typeof name === "string" && rule && typeof rule.parse === "function") {
      return true;
    }

    throw new Error(name + " is not a complete rule. A complete rule must contain `parse` function.");
  },

  parse(obj, ruleset) {
    if (!obj) {
      return obj;
    }
    for (const key in ruleset) {
      let value;
      const rule = ruleset[key];
      if ((value = obj[key]) != null) {
        obj[key] = this.parsers[rule].parse(value);
      }
    }

    return obj;
  },
};

Parser.addParser("binary", {
  parse(value) {
    return /^(true|[1-9]+[0-9]*)$/i.test(value) ? 1 : 0;
  },
});

Parser.addParser("lowercase", {
  parse(value) {
    return value.toString().toLowerCase();
  },
});

Parser.addParser("uppercase", {
  parse(value) {
    return value.toString().toUpperCase();
  },
});

Parser.addParser("integer", {
  parse(value) {
    return parseInt(value, 10);
  },
});

Parser.addParser("array", {
  parse(value) {
    if (value instanceof Array) {
      return value;
    }
    if (typeof value === "string") {
      return value.split(",");
    }
    return [value];
  },
});

module.exports = Parser;
