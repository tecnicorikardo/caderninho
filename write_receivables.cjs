const fs = require("fs");
const c = fs.readFileSync("write_receivables_content.txt", "utf8");
fs.writeFileSync("web/src/pages/ReceivablesPage.tsx", c, "utf8");
console.log("written", c.length, "chars");
