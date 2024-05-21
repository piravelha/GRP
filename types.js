let Int = (rank, len) => ({
  kind: "Type",
  type: "Int",
  rank,
  len,
})

let Any = {
  kind: "Type",
  type: "Any"
}
  function unify(...types) {
    let first = types[0]

    for (let t of types) {
      if (t === undefined) continue
      if (t.type === "Any") continue
      if ([
        "number",
        "string",
        "boolean"
      ].includes(typeof t)) {
        if (t !== first) {
          throw new Error(`Failed to unify types '${first}' and '${t}'.`)
        }
        continue
      }
      for (let key in t) {
        if (t[key] === first[key]) continue
        if (first[key] === undefined || t[key] === undefined) continue
        unify(first[key], t[key])
      }
    }
  }
  function compare(type, param) {
    let broad = {
      ...type,
      rank: undefined,
      len: undefined,
    }
    unify(broad, param.type)
    if (type.rank < param.minRank) {
      throw new Error("ramirichane")
    }
  }

let maxRank = (x, y) => x.rank > y.rank ? x : y

let maxOfMinRank = (x, y) => x.minRank > y.minRank ? x : y

let assertHigherRank = (x, y, amount) => {
  if (x.rank - y.rank < amount) {
    throw new Error("idk")
  }
}

let types = {
   "+^": {
    kind: "Type",
    type: "Monadic",
    x: {
      kind: "Parameter",
      type: Int(undefined, undefined),
      minRank: 0,
      value(x) {
        return Int(
          x.rank,
          x.len,
        )
      },
    },
     rank: 0,
     len: [],
   },
  "+": {
    kind: "Type",
    type: "Dyadic",
    x: {
      kind: "Parameter",
      type: Int(undefined, undefined),
      minRank: 0,
    },
    y: {
      kind: "Parameter",
      type: Int(undefined, undefined),
      minRank: 0,
    },
    value(x, y) {
      let hr = maxRank(x, y)
      return Int(
        hr.rank,
        hr.len,
      )
    },
    rank: 0,
    len: [],
  },
  "-": {
    type: "Dyadic",
    x: {
      type: Int(undefined, undefined),
      minRank: 0,
    },
    y: {
      type: Int(undefined, undefined),
      minRank: 0,
    },
    value(x, y) {
      return maxRank(x, y)
    },
    rank: 0,
    len: [],
  },
  "*": {
    type: "Dyadic",
    x: {
      type: Int(undefined, undefined),
      minRank: 0,
    },
    y: {
      type: Int(undefined, undefined),
      minRank: 0,
    },
    value(x, y) {
      return maxRank(x, y)
    },
    rank: 0,
    len: [],
  },
  "/": {
    type: "Dyadic",
    x: {
      type: Int(undefined, undefined),
      minRank: 0 
    },
    y: {
      type: Int(undefined, undefined),
      minRank: 0,
    },
    value(x, y) {
      return maxRank(x, y)
    },
    rank: 0,
    len: [],
  },
  "id": {
    kind: "Type",
    type: "Monadic",
    x: {
      kind: "Parameter",
      type: Any,
      minRank: 0,
    },
    value(x) {
      return x
    },
    rank: 0,
    len: [],
  },
  "reduce": {
    kind: "Type",
    type: "Dyadic",
    x: {
      kind: "Parameter",
      type: {
        kind: "Type",
        type: "Dyadic",
        x: {
          kind: "Parameter",
          type: Any,
          minRank: 0,
        },
        y: {
          kind: "Parameter",
          type: Any,
          minRank: 0,
        },
        rank: 0,
        len: [],
      },
      minRank: 0,
    },
    y: {
      kind: "Parameter",
      type: Int(undefined, undefined),
      minRank: 1,
    },
    value(f, xs) {
      assertHigherRank(xs, f, 1)
      let hr = maxRank(f.x, f.y)
      let x = {
        ...xs,
        rank: xs.rank - 1,
        len: xs.len.slice(0, xs.len.length - 1)
      }
      compare(x, maxOfMinRank(f.x, f.y))
      let res = f.value(x, x)
      compare(res, hr)
      return res
    }
  }
}

module.exports = {
  types,
  unify,
  compare
}
