const parser =
  require("./parser")
const fs = require("fs")

const removeBackslashes = code => {
  code = code.replace(/\s*\\\s+/, " ")
  code = code.replace(/;.+/, "")
  if (/\s*\\\s+/.test(code)) {
    return removeBackslashes(code)
  }
  if (/;.+/.test(code))
    return removeBackslashes(code)
  return code
}

let file = process.argv[2]

let result = parser.parse(removeBackslashes(fs.readFileSync(
  file,
  "utf-8",
)))

fs.writeFileSync(file.split(".grp") + ".lua", result)

