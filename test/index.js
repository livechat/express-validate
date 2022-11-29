const express = require("express");
const validator = require("../src/express-validate");

const app = express();
app.use(express.json());
app.use(validator({ exposeMixedParams: true }));

app.get("/", function (req, res) {
  req.parse({ number: "integer" });

  req.validate({
    name: { rule: "required", message: "%s is required u A-HOLE!" },
    login: [
      { rule: "required", message: "%s is required u A-HOLE2222!" },
      { rule: "minLength", minLength: 10 },
      "email",
    ],
    number: [
      { rule: "integer", message: "Numbers muthaf-er, do you speak it?!" },
      { rule: "between", low: 10, high: 20 },
    ],
  });

  return res.send("it's ok, dude");
});

app.listen(3000, () => console.log("I'm listening."));
