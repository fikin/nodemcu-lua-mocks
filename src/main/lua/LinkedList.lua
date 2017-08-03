--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

--[[
Credits to https://gist.github.com/MichaelCarius/6681865 for offering initial implementation version.
]]--

local LinkedList = {}

function LinkedList.create()
    local self = {}

    return setmetatable(self, {__index = LinkedList})
end

function LinkedList:append(x)
    local node = {data = x, previous = self.tail}
    self[x] = node

    if self.tail then
        self.tail.next = node

    else
        self.head = node
    end
    
    self.tail = node
end

function LinkedList:prepend(x)
    local node = {data = x, next = self.head}
    self[x] = node

    if self.head then
        self.head.previous = node

    else
        self.tail = node
    end

    self.head = node
end

function LinkedList:insertBefore(key, x)
    local keyNode = self[key]
    local node = {data = x, next = keyNode}

    if not keyNode then
        error("bad key")
    end

    self[x] = node

    if keyNode == self.head then
        self.head = node

    else
        keyNode.previous.next = node
        node.previous = keyNode.previous
    end

    keyNode.previous = node
end

function LinkedList:insertAfter(key, x)
    local keyNode = self[key]
    local node = {data = x, previous = keyNode}

    if not keyNode then
        error("bad key")
    end

    self[x] = node

    if keyNode == self.tail then
        self.tail = node

    else
        keyNode.next.previous = node
        node.next = keyNode.next
    end

    keyNode.next = node
end

function LinkedList:remove(x)
    local node = self[x]
    self[x] = nil

    if not node then
        error("list does not contain that data")
    end

    if node.previous then
        node.previous.next = node.next

    else
        self.head = node.next
    end

    if node.next then
        node.next.previous = node.previous

    else
        self.tail = node.previous
    end
end

function LinkedList:after(x)
    local node = self[x].next
    if not node then
        node = self.head
    end

    return node.data
end

function LinkedList:before(x)
    local node = self[x].previous
    if not node then
        node = self.tail
    end

    return node.data
end

function LinkedList:each()
    local current = self.head

    return function()
        if not current then
            return
        end

        local x = current.data
        current = current.next
        return x
    end
end

function LinkedList:toArray()
  local o = {}
  local current = self.head
  local indx = 0
  while current do
    indx = indx + 1
    o[indx] = current.data
    current = current.next
  end
  return o
end

function LinkedList:size()
  local count = 0
  local current = self.head
  while current do
    count = count + 1
    current = current.next 
  end
  return count
end

function LinkedList:contains(x)
  return not not self[x]
end

return LinkedList