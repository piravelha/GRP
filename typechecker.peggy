{
 let _stack = []
  let evalStack = () => {
    if (_stack.length <= 1) return
    if (_stack[0].type === "Monadic") {
      let f = _stack.shift()
      let p = _stack.shift()
      _stack.unshift(f.value(p))
    } else if (_stack[0].type === "Dyadic"
      && _stack.length >= 3) {
      let f = _stack.shift()
      let l = _stack.shift()
      let r = _stack.shift()
      _stack.unshift(f.value(l, r))
    }
  }
  let { types, unify, compare } = require("./types")
  let env = {
    ...types
  }
}

Program
  = vs : (_ VariableDef _)* _
    e : Expression _ {
    e()
    return _stack
  }

Expression
  = BinaryCall
  / UnaryCall
  / Atom

VariableDef
  = name : Name _
    "{" _
    val : Expression _ "}" {
    val()
    let v = _stack.shift()
    evalStack()
    env[name] = v
    return {
      kind: "Definition",
    }
  }

BinaryCall
  = f : Atom _
    l : Atom _
    r : BinaryCall {
    return () => {
      r()
      l()
      f()
      let f2 = _stack.shift() 
      let l2 = _stack.shift()
      if (f2.type === "Dyadic") {
        let r2 = _stack.shift()
        compare(r2, f2.y)
        compare(l2, f2.x)
        _stack.unshift(f2.value(l2, r2))
        evalStack()
      } else {
        compare(l2, f2.x)
        _stack.unshift(f2.value(l2))
        evalStack()
      }
    }
  } / UnaryCall

UnaryCall
  = f : Atom _
    p : UnaryCall {
    return () => {
      p()
      f()
      let f2 = _stack.shift()
      let p2 = _stack.shift()
      if (f2.type === "Monadic") {
        compare(p2, f2.x)
        _stack.unshift(f2.value(p2))
        evalStack()
      } else {
        _stack.unshift(p2)
        evalStack()
        _stack.unshift(f2)
        evalStack()
      }
    }
  } / Atom

List
  = "[" _ h : Atom _
    t : (_ Atom _)* _ "]" {
    t = t.map(e => e[1])
    unify(h, ...t)
    return () => {
      h()
      t.forEach(a => a())
      let newElems = []
      for (let i = [h, ...t].length - 1; i >= 0; i--) {
        newElems.push(_stack.shift())
        evalStack()
      }
      unify(...newElems)
      _stack.unshift({
        ...newElems[0],
        rank: newElems[0].rank + 1,
        len: [newElems.length, ...newElems[0].len],
      })
      evalStack()
    }
  }

Atom
  = Number
  / Identifier
  / List
  / "(" e : Expression ")" {
    return e
  }

Identifier
  = n : Name {
    return () => {
      _stack.unshift(env[n])
    }
  }

Name
  = h : [^ \n\r\t0-9()\[\]{}:]
    t : [^ \n\r\t0-9()\[\]{}]* {
    return [h, ...t].join("")
  }

Number
  = [0-9]+ {
    return () => {
      _stack.unshift({
        kind: "Type",
        type: "Int",
        rank: 0,
        len: [],
      })
    }
  }

_ "whitespace"
  = [ \n\r\t]*
