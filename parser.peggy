{
  const fs = require("fs")
}

Program
  = vs : (_n
    VariableDef _n)*
    _n e : Statement _n {
    let lib = fs.readFileSync(
      "lib.lua",
      "utf-8",
    )

    return lib
      + vs.map(v => v[1]).join("\n")
      + e
      + "\n\n_EVAL_STACK()"
  }

Expression
  = List
  / BinaryCall
  / UnaryCall
  / Atom

Statement
  = BinaryStatement 
  / UnaryStatement
  / AtomStatement

LazyStatement
 = "\\" a : AtomStatement {
    return a.replace("_EVAL_STACK()", "")
  }

Lazy
 = "\\" a : Atom {
    return a
  }

VariableDef
  = _n name : Name _
    ":=" _ val : Statement _n {
    return (
      `local function `
    + `${name}()\n`
    + val
    + `\nend\n`
    )
  }

IdentifierStatement
  = id : Identifier {
    return (
      `_STACK:push(`
    + `${id})\n`
    + `_EVAL_STACK()`
    )
  }

ListStatement
  = l : List {
    return `_STACK:push(${l})\n_EVAL_STACK()`
  }

List
  = "[" _ h : Atom _
    t : (_ Atom _)* _ "]" {
    return `{${[h, ...t.map(e => e[1])].join(", ")}}`
  }

BinaryStatement
  = f : AtomStatement _
    l : AtomStatement _
    r : BinaryStatement {
    let str = ""
    return `${r}\n${l.replace("\n_EVAL_STACK()", "")}\n${f}`
  }
  / l : AtomStatement _
    ":" f : AtomStatement _
    r : BinaryStatement {
    return `${r}\n${l}\n${f}`
  }
  / UnaryStatement

UnaryStatement
  = f : AtomStatement _
    p : UnaryStatement {
    return `${p}\n${f}`
  }
  / AtomStatement

BinaryCall
  = f : Atom _
    l : Atom _
    r : BinaryCall {
    return [f, l, r]
  } / InfixCall

InfixCall
  = l : Atom _
    ":" f : Atom _
    r : InfixCall {
      return [f, l, r]
  }
  / Atom

UnaryCall
  = f : Atom _
    p : UnaryCall {
    return [f, p]
  }
  / Atom

AtomStatement
  = NumberStatement
  / StringStatement
  / IdentifierStatement
  / ListStatement
  / "(" _ s : Statement _ ")" {
    return s
  }

Atom
  = Number
  / String
  / Identifier
  / List
  / "(" _ e : Expression _ ")" {
    return e
  }

Identifier
 = n : Name {
    return `${n}()`
  }

Name
  = h : [^ \n\r\ta-zA-Z0-9()\[\]{}:@\\]
    t : [^ \n\r\ta-zA-Z0-9()\[\]{}\\]* {
    let id = [h, ...t].map(c => "_" + c.codePointAt(0)).join("")
    return (
      `${id}`
    )
  }
  / Word

Word
  = h : [a-zA-Z]
    t : [^ \n\r\t()\[\]{}\\]* {
      let id = [h, ...t].map(c => /[a-zA-Z]/.test(c) ? c : "_" + c.codePointAt(0)).join("")
    return id
  }

StringStatement
  = s : String {
    return `_STACK:push(${s})\n_EVAL_STACK()`
  }

NumberStatement
  = n : Number {
    return `_STACK:push(${n})\n_EVAL_STACK()`
  }

String
  = '"' cs : [^"]* '"' {
    return `{${cs.map(c => `"${c}"`).join(", ")}, _STRING = true}`
  }

Number
  = ds : [0-9]+ {
    let n = ds.join("")
    return n
  }

_ "whitespace"
  = [ \t\r]*

_n "whitespace"
  = [ \n\t\r]*
