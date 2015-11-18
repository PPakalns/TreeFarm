-- Author: Xoandbit
--
-- Read data from file
-- Saved data in file must be in textutils.serialize
function readData(file)
  if (fs.exists(file) == false) then
    return  nil
  end

  local f=fs.open(file, "r")
  local s=f.readAll()
  return textutils.unserialize(s)
end

-- Save data in file
function writeData(file, data)

  if (fs.exists(file)) then
    fs.delete(file)
  end


  local f=fs.open(file, "w")
  f.write(textutils.serialize(data))
  f.close()
end

-- Clear screen and draw border around it
function Decorate(screen,border)
  if (screen==nil) then
    return
  end
  if (border==nil) then
    border=" "
  end

  local w,h,i
  w,h=screen.getSize()

  screen.clear()

  for i=1,w do
    screen.setCursorPos(i,1);
    screen.write(border)
    screen.setCursorPos(i,h);
    screen.write(border)
  end

  for i=1,h do
    screen.setCursorPos(1,i)
    screen.write(border);
    screen.setCursorPos(w,i)
    screen.write(border);
  end
end


-- Write text at specific cordinates on screen
-- clearLine - clear all line
-- hidden  - replaces characters with "*"
function WriteText(screen,x,y,text,clearLine,hidden)
  if (text==nil) then
    text=""
  end

  if (screen==nil) then
    screen=term
  end

  screen.setCursorPos(x,y)
  if (clearLine==true) then
    screen.clearLine()
  end

  cnt = string.len(text)

  if (hidden==true) then
    for i=1,cnt do
      screen.write("*")
    end
  else
    for i=1,cnt do
      screen.write(string.sub(text,i,i))
    end
  end

end

-- Write multiple values on screen from data table
-- example data definition       data={a,b,c,d}
function WriteInLine(screen, x,y, data)
  screen.setCursorPos(x,y)
  if (data==nil) then return 0 end
  for i=1,#data do
    screen.write(data[i])
    screen.write(" ")
  end
end

-- Read user input, opens new screen on top of parent screen
-- number - if user need to input integer
-- password - user input in screen output is replaced with "*"
function ReadUserInput(parentscreen, question, number, password, x, y, x2, y2)
  if (parentscreen==nil) then
    parentscreen=term.current();
  end

  if (number==nil) then
    number=false
  end

  if (password==nil) then
    password=false
  end

  if (y2==nil) then
    x,y=3,3
    x2,y2=parentscreen.getSize()
    x2,y2= x2 -5, y + 7

  end

  local screen, ev, text, txtlen, cursorpos
  screen=window.create(parentscreen, x, y, x2-x+1, y2-y+1, true)

  ev={}
  text=""
  txtlen=0
  cursorpos=1
  term.setCursorBlink(true)

  while (true) do

    if (ev[1]=="char") and (number~=true or tonumber(ev[2])~=nil) then
      if (cursorpos>txtlen) then
        text=text..ev[2]
        cursorpos=cursorpos+1
        txtlen = txtlen + 1
      else

        tmp=string.sub(text,1,cursorpos-1)..ev[2]..string.sub(text,cursorpos)
        text=tmp;
        cursorpos=cursorpos+1
        txtlen = txtlen + 1
      end


    elseif (ev[1]=="key") then
      if (ev[2]==keys.left)then
        cursorpos=math.max(1,cursorpos-1)

      elseif (ev[2]==keys.right) then
        cursorpos=math.min(txtlen+1,cursorpos+1)

      elseif (ev[2]==28) then -- 28 ENTER key
        break; -- return text
      elseif (ev[2]==14 and cursorpos>1) then --backspace

        tmp=string.sub(text,1,cursorpos-2)

        if (tmp==nil)then
          tmp=""
        end

        text=string.sub(text,cursorpos)
        if (text==nil) then
          text=""
        end

        text=tmp .. text
        txtlen=txtlen-1

        cursorpos=math.max(1,cursorpos-1)
      end
    end

    Decorate(screen, "#")
    WriteText(screen,3,3,question,false)
    WriteText(screen,5,5,text,false,password)
    screen.setCursorPos(5+cursorpos-1,5)

    ev = {os.pullEventRaw()}

  end


  screen.setCursorBlink(false)
  if (number) then
    return tonumber(text)
  end

  return text;
end




-- os.pullEvent loger
-- Writes log to screen
function DisplayEvents(parentscreen)
  if (parentscreen==nil) then
    parentscreen=term.current()
  end

  local w,h,screen, data, ev, tmp

  w,h=parentscreen.getSize()
  screen=window.create(parentscreen,1,1,w,h)

  data = readData("event.log")
  if (data==nil) then
    data = {}
  end

  ev={}

  while (true) do
    local message=""
    i=1
    while (ev[i]~=nil) do

      message= message.." "..tostring(ev[i])
      i=i+1
    end

    local w,h=screen.getSize()

    table.insert(data, 1, message)
    table.remove(data, h+1)
    Decorate(screen);
    for i=1,h do
      WriteText(screen,1,i,data[i],true)
    end

    writeData("event.log", data)

    ev = {os.pullEventRaw()}
  end
end

-- Return value of table - data[x] | data[x][y] etc
function Tget(data,x,y,z,f)

  if (x==nil) or (data==nil) then
    return data
  else
    if (data[x]==nil) then
      return nil
    else
      return Tget(data[x],y,z,f)
    end
  end
end

-- Set value to table - data[x]=value | data[x][y]=value etc
function Tset(data,value,x,y,z,f)

  if (x==nil) then
    return value
  else
    if (data==nil) then
      data={}
    end
    if (data[x]==nil) then
      data[x]={}
    end

    data[x]= Tset(data[x], value, y, z, f)
    return data
  end
end

-- Move turtle forward
function tforward()
  if (turtle.forward()) then
    if (robot["f"]==0) then robot["z"]=robot["z"]+1
    elseif (robot["f"]==1) then robot["x"]=robot["x"]-1
    elseif (robot["f"]==2) then robot["z"]=robot["z"]-1
    elseif (robot["f"]==3) then robot["x"]=robot["x"]+1
    end

    robot["o"]=true
    writeData("robot.log",robot)
    return true
  else
    robot["o"]=false
    return false
  end
end

-- Move turtle back
function tback()
  if (turtle.back()) then
    if (robot["f"]==0) then robot["z"]=robot["z"]-1
    elseif (robot["f"]==1) then robot["x"]=robot["x"]+1
    elseif (robot["f"]==2) then robot["z"]=robot["z"]+1
    elseif (robot["f"]==3) then robot["x"]=robot["x"]-1
    end

    robot["o"]=true
    writeData("robot.log",robot)
    return true
  else
    robot["o"]=false
    return false
  end
end

-- Move turtle up
function tup()
  if (turtle.up()) then
    robot["y"]=robot["y"]+1

    robot["o"]=true
    writeData("robot.log",robot)
    return true
  else
    robot["o"]=false
    return false
  end
end

--Move turtle down
function tdown()
  if (turtle.down()) then
    robot["y"]=robot["y"]-1
    robot["o"]=true
    writeData("robot.log",robot)
    return true
  else
    robot["o"]=false
    return false
  end
end

--Turn turtle anti-clockwise
function tturnLeft()
  if (turtle.turnLeft()) then
    robot["f"]=robot["f"]+4-1
    while (robot["f"]>3) do
      robot["f"]=robot["f"]-4
    end

    robot["o"]=true
    writeData("robot.log",robot)
    return true
  else
    robot["o"]=false
    return false
  end
end

--turn turtle clockwise
function tturnRight()
  if (turtle.turnRight()) then
    robot["f"]=robot["f"]+4+1
    while (robot["f"]>3) do
      robot["f"]=robot["f"]-4
    end

    robot["o"]=true
    writeData("robot.log",robot)
    return true
  else
    robot["o"]=false
    return false
  end
end

-- turn turtle to specific direction f=[0;4]
function tturn(direction)
  if (direction<0 or direction>3) then
    return true
  end

  local cf=robot.f
  if (direction==cf) then
    return true
  end

  r = direction + 4 - cf
  while (r>3) do
    r=r-4
  end
  l = cf + 4 - direction
  while (l>3) do
    l = l-4
  end

  if (r<l) then
    while (robot.f~=direction) do
      tturnRight()
    end

  else
    while (robot.f~=direction) do
      tturnLeft()
    end
  end

  return true
end

-- Calculates cordinate of block next to turtle
-- Possible direction - UP DOWN FORWARD RIGHT BACK LEFT
function calculateBlockCordfromRobotCord(wdirection)
  local cc = {
    x=robot.x,
    y=robot.y,
    z=robot.z
  }

  tf=robot.f
  if (tf==nil) then tf=0 end

  if (wdirection=="UP") then tf=-4
  elseif (wdirection=="DOWN") then tf=-5
  elseif (wdirection=="FORWARD") then tf=tf+0
  elseif (wdirection=="RIGHT") then tf=tf+1
  elseif (wdirection=="BACK") then tf=tf+2
  elseif (wdirection=="LEFT") then tf=tf+3 end


  while (tf>3) do   --tf=[0;3]
    tf=tf-4
  end

  if (tf<0) then tf=-tf end -- for UP and DOWN


  if (tf==0) then cc.z=cc.z+1
  elseif (tf==1) then cc.x=cc.x-1
  elseif (tf==2) then cc.z=cc.z-1
  elseif (tf==3) then cc.x=cc.x+1
  elseif (tf==4) then cc.y=cc.y+1
  elseif (tf==5) then cc.y=cc.y-1  end

  return cc
end

-- Move turtle to one possible direction
-- UP DOWN FORWARD
function _MOVE(movefunction,direction) -- direction  UP DOWN FORWARD

  local try, maxtry = 0, 5

  while (true) do
    try= try+1
    local success, blockdataT , blockdata= nil, nil, nil
    if (direction=="UP") then
      success, blockdataT= turtle.inspectUp()
    elseif (direction=="DOWN") then
      success, blockdataT= turtle.inspectDown()
    elseif (direction=="FORWARD") then
      success, blockdataT= turtle.inspect()
    else
      print(" ERROR - _MOVE ")
      exit()
    end

    if (success == false) then -- air - can move

      if (movefunction()) then
        return true
      else
        if (turtle.getFuelLevel()==0) then
          turtle.select(16)
          if (turtle.refuel(1)) then
            print("REFUEL")
          else
            print("NO MORE FUEL AT SLOT 16")
          end
        end
        -- if not try again
        -- ???????????????
      end
    else

      blockdata=blockdataT.name
      -- 1. BlockLaunchTest
      -- 2. TryToBreak
      -- 3. TryToGoAroundIt
      --
      local continue, allowtobreak, returnval = true, false, nil
      blockcord = calculateBlockCordfromRobotCord(direction)

      -- Lets check if we have to call a function
      if (BlockLaunchTest[blockdata]) then
        print("Block launch test ",blockdata)
        continue, allowtobreak, returnval=BlockLaunchTest[blockdata](blockcord)
        if (returnval~=nil) then
          return returnval
        end
      end

      if (continue) then
        if (AllowedToBreak[blockdata] or allowtobreak) then
          print("BREAK BLOCK")
          if (direction=="UP") then
            turtle.digUp()
          elseif (direction=="DOWN") then
            turtle.digDown()
          elseif (direction=="FORWARD") then
            turtle.dig()
          end
        else  -- Add to nonbreakable block list
          print("Adding to NO BREAK")
          if string.find(blockdata, "Turtle") then
            addNonBreakableBlock(blockcord, 4)
          else
            addNonBreakableBlock(blockcord, NonBreakableBlockTimer)
          end
          return false
        end
      end
    end

  end

  return false  -- failed to move
end

-- Turtle execute a move array,,, array consists of integer
-- [0;3] f    4 - up  5 - down
function tmove(movelist)
  while (robot.to.go and robot.to.calculated) do
    sleep(0)
    if (turtle.detect()==false) then
      turtle.suck()  -- Try to pick items from ground
    end

    if (turtle.detectDown()==false) then
      turtle.suckDown()  -- Try to pick items from ground
    end

    local try=0 -- How many times will try
    local f=table.remove(movelist)
    if (f==nil or f>5 or f<0) then
      break
    end
    tturn(f)
    if (f==4) then
      if (_MOVE(tup,"UP")==false) then
        return false
      end
    elseif (f==5) then
      if (_MOVE(tdown,"DOWN")==false) then
        return false
      end
    else
      if (_MOVE(tforward,"FORWARD")==false) then
        return false
      end
    end
  end

  return true

end

-- Compare if cordinates are equal
function tcomparecord(a,b)
  if (a.x==b.x and a.y==b.y and a.z==b.z) then
    return true
  else
    return false
  end
end

-- Add cordinate b to a, and checking a facing direction and expecting that
-- Function rotates b cordinates to match with a direction
function taddCord(a, b) -- a cordinates with face   b normal cordinates
  local aplusb = {}
  aplusb.x=b.x
  aplusb.y=b.y
  aplusb.z=b.z
  if (a.f==nil) then  -- Maybe normal cordinate addition
    a.f=0
  end

  local tf=a.f
  while (tf>0) do -- ROTATE CORDINATES
    local tmp =  aplusb.x
    aplusb.x = - aplusb.z
    aplusb.z = tmp
    tf=tf-1
  end

  aplusb.x=aplusb.x + a.x
  aplusb.y=aplusb.y + a.y
  aplusb.z=aplusb.z + a.z

  return aplusb
end

-- Pytagorean distance between a and b cordinates
function distance(a,b)
  local x,y,z
  x=a.x-b.x
  y=a.y-b.y
  z=a.z-b.z
  return math.sqrt((x*x)+(y*y)+(z*z))
end

-- Manhetens distance between a and b cordinates
function tdistance(a,b)
  if (a==nil or b==nil) then
    return 100000000  -- infinity
  end
  return (math.abs(a.x-b.x)+math.abs(a.y-b.y)+math.abs(a.z-b.z))
end

-- Moves turtle to target cordinates
-- Target cordinates need to be set at robot.to
-- Variable robot.to.go = true  needs to be set
-- When target is reached robot.to.go is set to false
--
-- This functions is written to run in parrallel api with the main program
-- which sets (robot.to) in this api for robot to move
function RobotMoveTo()
  print("Robot move to listener started")
  while (true) do
    sleep(1)
    if (robot==nil) then
      robot={to={}}
    elseif (robot.to==nil) then
      robot.to={}
    end

    if (robot.to.go==true) then
      print("Starting to move")
      while (tcomparecord(robot,robot.to)==false and robot.to.go) do
        local movelist=Apath(robot, robot.to, true)
        robot.to.calculated=true
        recalc=tmove(movelist)
        if (recalc~=true or #movelist==0) then
          sleep(3)
        end
      end
      robot.to.go=false
      -- FINISHED
    end
  end
end

-- Startuo function for turtle
-- Ask user to input robot cordinates
function RunRobot(parentscreen)

  if (parentscreen==nil) then
    parentscreen=term.current()
  end

  local w,h=parentscreen.getSize()
  local screen=window.create(parentscreen,3,2,w-2,h-2,true)
  Decorate(screen)

  local robot = readData("robot.log")
  if (robot==nil) then
    robot={}
  end

  robot.id=os.getComputerID()
  robot.ID=robot.id
  if (robot["installed"]==nil) then
    robot["x"]=ReadUserInput(screen,"Turtle x position",true)
    robot["y"]=ReadUserInput(screen,"Trutle y position",true)
    robot["z"]=ReadUserInput(screen,"Turtle z position",true)
    while (robot["f"]==nil) do
      robot["f"]=ReadUserInput(screen,"Turtle direction f [0;3]",true)
      if (robot["f"]<0 or robot["f"]>3) then
        robot["f"]=nil;
      end
    end
    robot["installed"]=true
    robot.to={}
    robot.to.go=false
    robot.to.calculated=false
  end

  writeData("robot.log",robot)
  screen.setVisible(false)
  return robot
end

-- Add block what is allowed to break when robot is moving around
function addAllowedToBreak(block)
  AllowedToBreak[block]=true;
end

-- Remove allowed to break block
function removeAllowedToBreak(block)
  AllowedToBreak[block]=nil;
end

-- Add function to be runned when turtle path is blocked by a block
-- For specific callFunction expected return variables check _MOVE function
function addBlockTest(block,callFunction)
  BlockLaunchTest[block]=callFunction
end

-- Remove in addBlockTest(block,callFunction) setted callFunction
function removeBlockTest(block)
  BlockLaunchTest[block]=nil
end

-- Function is called when turtle path is blocked by a block
-- function saves block position for timeoutsec / A* pathfinding uses this
-- cordinate to check if position is empty
function addNonBreakableBlock(blockcord, timeoutsec)
  local timer=nil
  if (timeout~=nil) then
    timer = os.startTimer(timeoutsec)
  end
  blockcord.timer=timer

  table.insert(NonBreakableBlock,blockcord)
end

-- USE THIS IF using built in navigation functions
-- Delete NonBreakableBlock after some time ( timeoutsec )
function turtleUpdate()
  -- Updating breakable block database - maybe turtle or tree ?
  while (true) do
    ev = { os.pullEventRaw() }
    -- Check something
    if (ev[1]=="timer")then
      for i=1,#NonBreakableBlock do
        if (NonBreakableBlock[i].timer==ev[2]) then
          print("REMOVED NonBreakableBlock")
          table.remove(NonBreakableBlock,i)
          break
        end
      end
    end
  end
end

-- Setting api global variables
--
robot = nil
destination = nil
if turtle then

  AllowedToBreak = {}

  NonBreakableBlockTimer = 30

  NonBreakableBlock = {}
  BlockLaunchTest = {}
  --[[
  {x,y,z,timer}
  ]]--
  robot=RunRobot()
  turtle.select(1)
end



-- COROUTINE CONTAINER - FOR SIMPLER EVENT FILTERING

CoroutineControl = {}
function CoroutineControl.new(self)
  local new = {}
  setmetatable(new, {__index = self})
  new.idcnt=1 --Coroutine id cnter
  new.coroutines={}  -- coroutine list
  new.run=true
  return new
end

function CoroutineControl.addCoroutine(self,func,Arg)

  local id=self.idcnt

  self.idcnt = self.idcnt + 1

  self.coroutines[id]={}
  self.coroutines[id].funcID=func
  self.coroutines[id].id=id
  self.coroutines[id].run=true
  self.coroutines[id].cID=coroutine.create(func)
  if (Arg) then  -- ADD ARG
    self.coroutines[id].ok, self.coroutines[id].requestedEvent =
    coroutine.resume(self.coroutines[id].cID, unpack( Arg ))
  else
    self.coroutines[id].ok, self.coroutines[id].requestedEvent =
    coroutine.resume(self.coroutines[id].cID)
  end
  return id
end

function CoroutineControl.loop(self)
  while (self.run) do
    ev = {os.pullEventRaw()}
    -- coroutine id and coroutines table
    for id,coro in pairs(self.coroutines) do
      if (coro.run) then
        if (ev[1]==coro.requestedEvent or coro.requestedEvent==nil) then
          coro.ok, coro.requestedEvent =
          coroutine.resume(coro.cID,unpack( ev ))
        end
      end
    end
  end
end


-- PASTE CORDINATES
function tpasteCord(from,to)
  to.x=from.x
  to.y=from.y
  to.z=from.z
end

-- HEAP FUNCTIONS


function pushHeap(heap,data)
  if (heap==nil) then
    heap={}
  end
  if (heap.cnt==nil or heap.cnt<0) then
    heap.cnt=0
  end

  heap.cnt = heap.cnt+1
  heap[heap.cnt]=data

  local act=heap.cnt
  while (math.floor(act/2)>=1) do
    local div = math.floor(act/2)
    if (heap[div].V>heap[act].V) then
      local tmp=heap[div]
      heap[div]=heap[act]
      heap[act]=tmp
      act=div
    else
      break
    end
  end
end

function popHeap(heap)
  if (heap.cnt==nil or heap.cnt==0) then
    return nil
  else
    local retval = heap[1]
    heap[1]=heap[heap.cnt]
    heap[heap.cnt]=nil
    heap.cnt=heap.cnt-1

    local act, lc, rc, ch
    local act=1
    while (act*2 <= heap.cnt) do
      lc=act*2
      rc=lc+1
      if (rc<=heap.cnt and heap[rc].V<heap[lc].V) then
        ch=rc
      else
        ch=lc
      end

      if (heap[ch].V<heap[act].V) then
        local tmp=heap[ch]
        heap[ch]=heap[act]
        heap[act]=tmp
        act=ch
      else
        break
      end
    end

    return retval
  end
end

-- A* pathfinding
-- returns movelist (directions [0;5]  4 - UP    5 - DOWN)
function Apath(from, to, vertical)

  print(" A* recalculating ")

  local directions = {
    [ 0 ] = {x=0, z=1,y=0},
    [ 1 ] = {x=-1, z=0,y=0},
    [ 2 ] = {x=0, z=-1,y=0},
    [ 3 ] = {x=1, z=0,y=0},
    [ 4 ] = {x=0, z=0,y=1}, -- UP
    [ 5 ] = {x=0, z=0,y=-1}, --DOWN
  }

  local searchingDistance=25
  local heap,dist,cnt,elem,answ,answdist

  answdist = 10000000

  heap={}
  heap.cnt=0
  dist={}
  cnt=0

  elem={}
  tpasteCord(from,elem)
  elem.sD=0
  elem.eD=tdistance(elem,to)
  elem.V=elem.sD+elem.eD
  Tset(dist,-1,elem.x,elem.y,elem.z)
  pushHeap(heap,elem)

  while (cnt<searchingDistance and heap.cnt>0) do

    cnt = cnt + 1

    local act, desc, continue
    continue=true

    act = popHeap(heap)

    --CHECK IF CAN MOVE THROUGHT
    for i=1,#NonBreakableBlock do
      if (tcomparecord(NonBreakableBlock[i],act)) then
        continue=false
        cnt=cnt-1
        break
      end
    end

    if (continue==true) then --IF CAN MOVE THROUGHT THEN OK

      local face = Tget(dist, act.x,act.y,act.z)
      local distan = tdistance(act,to)
      if (distan < answdist) then
        answdist = distan
        answ = {}
        tpasteCord(act, answ)
        if (answdist==0) then
          break
        end
      end

      for f=0,5 do
          local actf={}
          actf.x = act.x + directions[f].x
          actf.y = act.y + directions[f].y
          actf.z = act.z + directions[f].z

          actf.sD = act.sD + 1
          actf.eD = tdistance(actf,to)
          actf.V=actf.eD + actf.sD

          if (face~=f) then actf.V = actf.V+0.5 end

          local parb = Tget(dist, actf.x, actf.y, actf.z)
          if (parb==nil) then
            pushHeap(heap,actf)
            Tset(dist,f,actf.x,actf.y,actf.z)
          end
      end
    end
  end

  heap=nil
  local movelist={}
  local f=Tget(dist,answ.x,answ.y,answ.z)
  while (f~=-1) do
    table.insert(movelist,f)
    if (f==0) then answ.z = answ.z -1
    elseif (f==1) then answ.x = answ.x +1
    elseif (f==2) then answ.z = answ.z +1
    elseif (f==3) then answ.x = answ.x -1
    elseif (f==4) then answ.y = answ.y -1
    elseif (f==5) then answ.y = answ.y +1
    end
    f = Tget(dist, answ.x,answ.y,answ.z)
  end

  return movelist
end
