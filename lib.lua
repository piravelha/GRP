
local _DEBUG = false

local _STACK = setmetatable({
  push = function(self, elem)
    if elem == nil then
      return
    end
    if _DEBUG then
      print("Pushing element: " .. _listRepr(elem))
    end
    if #self == 0 then
      self[1] = elem
      if _DEBUG then
        print("Stack: " .. _listRepr(self))
      end
      return
    end
    for i = #self + 1, 2, -1 do
      self[i] = self[i - 1]
    end
    self[1] = elem
    if _DEBUG then
      print("Stack: " .. _listRepr(self))
    end
  end,
  pop = function(self)
    if _DEBUG then
      print("Popping")
    end
    if #self == 0 then
      if _DEBUG then
        print("Stack: " .. _listRepr(self))
        return
      end
    end
    if #self == 1 then
      self[1] = nil
      if _DEBUG then
        print("Stack: " .. _listRepr(self))
      end
      return
    end
    for i = 1, #self do
      self[i] = self[i + 1]
    end
    if _DEBUG then
      print("Stack: " .. _listRepr(self))
    end
  end
}, {
  __newindex = function(self, key, val)
    rawset(self, key, val)
  end
})
local function _EVAL_STACK()
  if _DEBUG then
    print("Before eval: " .. _listRepr(_STACK))
  end
  

  if #_STACK >= 1 then
    if type(_STACK[1])
    == "table" and _STACK[1]._func then
      f, a, b = table.unpack(_STACK)
      if f._monadic then
        _STACK:pop()
        _STACK:pop()
        _STACK:push(f(a))
      elseif #_STACK >= 3 then
        _STACK:pop()
        _STACK:pop()
        _STACK:pop()
        _STACK:push(f(a, b))
      end
    end
  end

  if _DEBUG then
    print("After eval: " .. _listRepr(_STACK))
  end
end

local function _lazy(x)
  if type(x) == "table" and x._lazy then
    return x
  end
  return {
    _lazy = x
  }
end

local function _eager(x)
  if type(x) ~= "table" or not x._lazy then
    return x
  end
  return _eager(x._lazy())
end

local isTable = function(x)
  return type(x) == "table" and not x._func and not x._cons and not x._lazy
end

local isFunc = function(x)
  return type(x) == "table" and x._func
end

local function _ranknpoly(name, minRank, isDyadic, f)
  return setmetatable({
    _func = true,
    _monadic = not isDyadic,
    _dyadic = isDyadic
  }, {
    __tostring = function() return name end,
    __call = function(_, ...)
      local elems = {...}
      local function getMaxRank(arr, rank)
        if not isTable(arr) then
          return rank or 0
        end
        rank = rank or 0
        for _, e in pairs(arr) do
          return getMaxRank(e, rank + 1)
        end
      end
      local max = 0
      local maxArr = nil
      for _, e in pairs(elems) do
        local rank = getMaxRank(e)
        if rank > max then
          max = rank
          maxArr = e
        end
      end
      if not maxArr then
        return f(...)
      end
      local function getRank(list)
        if not isTable(list) then
          return 0
        end
        return 1 + getRank(list[1])
      end
      local function repOf(base, rep)
        if getRank(rep) > minRank then
          local new = {}
          for i, e in pairs(rep) do
            new[i] = repOf(base[i], e)
          end
          return new
        end
        if getRank(base) > minRank then
          local new = {}
          for i, e in pairs(base) do
            new[i] = repOf(e, rep)
          end
          return new
        end
        return rep
      end
      local newElems = {}
      for i, e in pairs(elems) do
        newElems[i] = repOf(maxArr, e)
      end
      local function maxLength(lists)
        local max = 0
        for i = 1, #lists do
          if isTable(lists[i]) then
            if #lists[i] > max then
              max = #lists[i]
            end
          end
        end
        return max
      end
      local function apply(lists)
        local max = 0
        for _, list in pairs(lists) do
          if getRank(list) > max then
            max = getRank(list)
          end
        end
        if max <= minRank then
          return f(table.unpack(lists))
        end
        local results = {}
        for i = 1, maxLength(lists) do
          local subs = {}
          for _, e in pairs(lists) do
            table.insert(subs, e[i])
          end
          results[i] = apply(subs)
        end
        return results
      end
      return apply(newElems)
    end,
  })
end

function _listRepr(list)
  if not isTable(list) or getmetatable(list) and getmetatable(list).__tostring then
    return tostring(list)
  end
  local str = "["
  local justChars = true
  for k, e in pairs(list) do
    if type(k) == "number" then
      if type(e) ~= "string" then
        justChars = false
      end
      local repr = _listRepr(e)
      if repr:find(" ") and not repr:sub(1, 1) == "[" then
        repr = "(" .. repr .. ")"
      end
      str = str .. repr .. " "
    end
  end
  if #list == 0 then return "[]" end
  if justChars or list._STRING then
    return table.concat(list, "")
  end
  return str:sub(1, -2) .. "]"
end

local function _printStack()
  for i, e in pairs(_STACK) do
    if type(i) == "number" then
      print(_listRepr(e))
    end
  end
end

local function _45_94()
  return _ranknpoly("-^", 0, false, function(n)
    return -n
  end)
end

local function _43()
  return _ranknpoly("+", 0, true, function(a, b)
    return a + b
  end)
end

local function _45()
  return _ranknpoly("-", 0, true, function(a, b)
    return a - b
  end)
end

local function _42()
  return _ranknpoly("*", 0, true, function(a, b)
    return a * b
  end)
end

local function _47()
  return _ranknpoly("/", 0, true, function(a, b)
    return a / b
  end)
end

local function println_33()
  return _ranknpoly("printlist!", math.huge, false, function(x)
    print(_listRepr(x))
    return x
  end)
end

local function range()
  return _ranknpoly("range", 0, true, function(min, max)
    local tbl = {}
    for i = min, max, 1 do
      table.insert(tbl, i)
    end
    return tbl
  end)
end

local function head()
  return _ranknpoly("head", 1, false, function(list)
    if list[0] == nil then
      error("Head of an empty list")
    end
    return list[0]
  end)
end

local function tail()
  return _ranknpoly("tail", 1, false, function(list)
    if list[0] == nil then
      error("Tail of empty list")
    end
    local new = {}
    for i = 2, #list do
      table.insert(new, list[i])
    end
    return new
  end)
end

local function length()
  return _ranknpoly("length", 1, false, function(list)
    return #list
  end)
end

local function filter()
  return _ranknpoly("filter", 1, true, function(pred, list)
    local new = {}
    for _, e in ipairs(list) do
      if pred(e) then
        table.insert(new, e)
      end
    end
    return new
  end)
end

local function sum()
  return _ranknpoly("sum", 1, false, function(list)
    local sum = 0
    for _, e in ipairs(list) do
      sum = sum + e
    end
    return sum
  end)
end

local function product()
  return _ranknpoly("product", 1, false, function(list)
    local product = 1
    for _, e in ipairs(list) do
      product = product * e
    end
    return product
  end)
end

local function reverse()
  return _ranknpoly("reverse", 1, false, function(list)
    local new = {}
    for i = #list, 1, -1 do
      table.insert(new, list[i])
    end
    return new
  end)
end

local function reduce()
  return _ranknpoly("reduce", 1, true, function(op, list)
    local new = nil
    for _, e in pairs(list) do
      if new == nil then
        new = e
      else
        new = op(new, e)
      end
    end
    return new
  end)
end

local function _43_43()
  return ranknpoly("++", 1, true, function(xs, ys)
    local new = {}
    for i = 1, #xs + #ys do
      if i <= #xs then
        table.insert(new, xs[i])
      else
        table.insert(new, ys[i])
      end
    end
    return new
  end)
end

local function upper()
  return _ranknpoly("upper", 0, false, function(c)
    return string.upper(c)
  end)
end

local function lower()
  return _ranknpoly("lower", 0, false, function(c)
    return string.lower(c)
  end)
end

function id()
  return _ranknpoly("id", 0, false, function(x)
    return x
  end)
end

local function False()
  return setmetatable({
    _cons = true,
    _name = "False",
  }, {
    __tostring = function()
      return "False"
    end
  })
end

local function True()
  return setmetatable({
    _cons = true,
    _name = "True",
  }, {
    __tostring = function()
      return "True"
    end
  })
end

local function even_63()
  return _ranknpoly("even?", 0, false, function(x)
    return x % 2 == 0 and True() or False()
  end)
end

local function None()
  return setmetatable({
    _cons = true,
    _name = "None",
  }, {
    __tostring = function()
      return "None"
    end,
  })
end

local function Some_35()
  return _ranknpoly("Some", math.huge, false, function(x)
    return setmetatable({
      _cons = true,
      _name = "Some",
      _args = {x},
    }, {
      __tostring = function()
        return "(Some " .. _listRepr(x) .. ")"
      end,
    })
  end)
end

local function Some()
  return _ranknpoly("Some#", 0, false, function(x)
    return setmetatable({
      _cons = true,
      _name = "Some",
      _args = {x},
    }, {
      __tostring = function()
        return "(Some " .. _listRepr(x) .. ")"
      end,
    })
  end)
end

local function map_45maybe()
  return _ranknpoly("map-maybe", 0, true, function(f, m)
    if m._name == "None" then
      return None()
    else
      return Some()(f(m._args[1]))
    end
  end)
end

local function filter_45maybe()
  return _ranknpoly("filter-maybe", 0, true, function(p, m)
    if m._name == "None" then
      return None()
    elseif p(m._args[1])._name == "True" then
      return m
    end
    return None()
  end)
end
