os.loadAPI("lain")
robot = lain.robot

-- CONFIG --
basechannel = 666
robotchannel = nil  -- nil - (Random modem channel)
modemSide="right"
reserveFuel=100  -- Min turtle fuel level
pingtimer=10
-- CONFIG END --

if (robotchannel~=nil) then
  robot.robotchannel=robotchannel
elseif (robot.robotchannel==nil) then
  robot.robotchannel=math.random(777,10000)
end

timeout = 5
refreshtimer = 1

Wood = {
  [ "minecraft:log" ]=true,
  [ "IC2:blockRubWood" ]=true,
  [ "minecraft:leaves" ]=true
}

Sapling = {
  [ "minecraft:sapling" ]=true,
  [ "IC2:blockRubSapling" ]=true
}

Dirt = {
  [ "minecraft:dirt" ]=true
}

Torch = {
  [ "minecraft:torch" ]=true
}

Fuel = {
  [ "minecraft:coal" ]=80,
  [ "minecraft:coal_block" ]=800,
}

-- When going to chop tree and target tree is blocking way
function FoundTree(cordinate) -- Continue, allowtobreak, return
  if (lain.tcomparecord(cordinate, robot.to)) then
    return true, true, nil
  else
    return true, false, nil
  end
end

function Ping()
  if (robot.dirt==nil) then robot.dirt=0 end
  if (robot.torch==nil) then robot.torch=0 end
  if (robot.sapling==nil) then robot.sapling=0 end

  local message = {
    ID = os.getComputerID(),

    robot = {
      x=robot.x,
      y=robot.y,
      z=robot.z,
      f=robot.f,
      state=robot.state,
      dirt=robot.dirt,
      torch=robot.torch,
      sapling=robot.sapling,
      fuel=robot.fuel,
    },
    request="ping"
  }
  modem.transmit(basechannel, robot.robotchannel, textutils.serialize(message) )
end

function TurtleTreeFarm(parentscreen, modem, robot)
  print("Tree Farm function launch")
  if (parentscreen==nil) then
    parentscreen = term.current()
  end
  if (modem==nil) then
    modem = peripheral.wrap(modemSide)
  end
  if (robot==nil) then
    robot=lain.robot
  end

  local w,h=parentscreen.getSize()
  local screen = window.create( parentscreen, 3,3, w-3, h-3)

  print("MODEM ",modem)
  modem.open(robot.robotchannel)

  local ping = os.startTimer(pingtimer)
  local refresh = os.startTimer(refreshtimer)

  -- Initializing if there was turtle restart
  local hometimer=os.startTimer(2)
  robot.timer=os.startTimer(timeout)

  print("STARTING TURTLE TREE FARM ID - ", os.getComputerID())
  print("STARTUP STATE - SUBSTATE = ",robot.state," - ",robot.substate)

  while (true) do
    lain.writeData("robot.log",robot)

    ev = {os.pullEventRaw()}

    if (ev[1]=="timer") then
      if (ev[2]==ping) then
        Ping()
        ping=os.startTimer(pingtimer)
      elseif (ev[2]==refresh) then
        refresh = os.startTimer(refreshtimer)
      end
    end

    if (robot.state==nil) then  -- INITIALIZE WORKER
      if (robot.substate==nil) then
        robot.substate=0;
      end
      if (robot.substate==0) then -- SEND startup message
        print("SENDING STARTUP")
        local message = {
          ID = os.getComputerID(),
          robot = {
            x=robot.x,
            y=robot.y,
            z=robot.z,
            f=robot.f,
            state=robot.state,
          },
          request="startup"
        }
        modem.transmit(basechannel, robot.robotchannel, textutils.serialize(message))
        robot.timer = os.startTimer(timeout)
        robot.substate=1
      elseif (robot.substate==1) then --WAITING for startup message
        if (ev[1]=="modem_message") then
          local message=textutils.unserialize(ev[5])
          if (message.target == os.getComputerID() ) then
            if (message.request=="startup") then
              print("STARTUP response received")
              robot.home=message.home
              robot.saplingc=message.saplingc
              robot.fuelc=message.fuelc
              robot.woodc=message.woodc
              robot.dirtc=message.dirtc
              robot.torchc=message.torchc
              robot.timer=nil -- unset timer
              robot.state=jobType.Home
              robot.substate=nil
              robot.jobqueue={}
            end
          end
        elseif (ev[1]=="timer") then
          if (ev[2]==robot.timer) then --RETRY sensing startup message
            robot.substate=0
          end
        end
      end

    elseif (robot.state==jobType.Home) then -- GOING HOME / AFTER RESOURCES
      if (robot.substate==nil or robot.substate==0 ) then --WAIT TWO SECONDS FOR JOB
        Ping()
        ping=os.startTimer(pingtimer)

        hometimer=os.startTimer(2)

        robot.substate=1
        robot.jobqueue={}
        robot.location=0
        robot.nextlocation=true

      elseif (robot.substate==1) then
        if (ev[1]=="timer") then
          if (ev[2]==hometimer) then --Move to home location after delay
            robot.substate=2
          end
        end
      elseif (robot.substate==2) then --GO to chests and home
          local movelocations = {
              [1] = robot.woodc,
              [2] = robot.saplingc,
              [3] = robot.fuelc,
              [4] = robot.torchc,
              [5] = robot.dirtc,
              [6] = robot.home
          }

          if (robot.nextlocation) then
              robot.nextlocation=false
              robot.location = robot.location + 1
              if (robot.location>#movelocations) then
                  robot.substate=3 --at home
              else
                  -- go to next location
                  lain.tpasteCord(movelocations[robot.location], robot.to)
                  robot.to.go, robot.to.calculated = true, false
              end
          end
      elseif (robot.substate==3) then
          -- home
          -- Do nothing, wait for job request
      end

      if (ev[1]=="modem_message") then --Job request
        local message=textutils.unserialize(ev[5])
        if (message.request=="job" and message.target==robot.id) then
          print("Received job request, adding to job queue")
          table.insert(robot.jobqueue,message)
        end
      end

    elseif (robot.state==jobType.Tree) then -- ChopingTree
      if (robot.substate==nil) then
        print("Copping tree")
        robot.substate=-1
        robot.subheight=0
        robot.chopUP=true
        lain.tpasteCord(robot.job.cord,robot.to)
        robot.to.go, robot.to.calculated = true, false
      end

      if (robot.substate==-1) then
        if (lain.tcomparecord(robot.to,robot)) then
          robot.to.go, robot.to.calculated = false, false
          robot.substate=0  -- START CHOP
        end
      end

      if (robot.substate==2) then
        -- TREE CHOPPING IS FINISHED
        local message = {
          ID = os.getComputerID(),
          request="job_done",
          jobid = robot.job.id,
          jobstatus = "DONE"
        }

        -- SENDING JOB DONE MESSAGE
        robot.subheight=nil
        robot.chopUP=nil
        robot.substate=nil
        robot.state=jobType.JobDone
        robot.job.message=message

      elseif (robot.substate==3) then
        -- Tree didnt grow
        local message = {
          ID = os.getComputerID(),
          request="job_done",
          jobid = robot.job.id,
          jobstatus = "NOT GROWN"
        }

        -- SENDING JOB DONE MESSAGE
        robot.subheight=nil
        robot.chopUP=nil
        robot.substate=nil
        robot.state=jobType.JobDone
        robot.job.message=message
      end

      --PLACING BLOCK
    elseif (robot.state==jobType.Torch or robot.state==jobType.Dirt or robot.state==jobType.Sapling) then 
      if (robot.substate==nil) then
        print("Going to place block")
        robot.substate=0
        lain.tpasteCord(robot.job.cord, robot.to)
        robot.to.go, robot.to.calculated = true, false
      end

      if (robot.substate==0 and lain.tcomparecord(robot, robot.to)) then
        robot.go = false
        robot.substate=1
      end

      if (robot.substate==2) then
        local message = {
          ID = os.getComputerID(),
          request="job_done",
          jobid = robot.job.id,
          jobstatus = ""
        }

        if (robot.state==jobType.Torch) then
          message.jobstatus="TORCH"
        elseif (robot.state==jobType.Dirt) then
          message.jobstatus="DIRT"
        elseif (robot.state==jobType.Sapling) then
          message.jobstatus="SAPLING"
        end

        robot.substate=nil
        robot.state=jobType.JobDone
        robot.job.message=message
      end
    elseif (robot.state==jobType.JobAccept) then -- Accepting job
      if (robot.substate==nil) then
        local message = {
          ID = os.getComputerID(),
          request = "accepted",
          jobid= robot.job.id,
        }
        modem.transmit(basechannel, robot.robotchannel, textutils.serialize(message))
        robot.timer = os.startTimer(timeout)
        robot.substate = 1
      elseif (robot.substate==1) then
        if (ev[1]=="modem_message") then
          local message=textutils.unserialize(ev[5])
          if (message.target == os.getComputerID()) then
            if (message.request=="accepted_response") then
              print("job accept response received")
              robot.timer=nil
              robot.state=robot.job.jobt
              robot.substate=nil
            elseif (message.request=="accepted_response_fail") then
              robot.state=jobType.Home
              robot.substate=nil
              robot.timer=nil
            end
          end
        elseif (ev[1]=="timer") then
          if (ev[2]==robot.timer) then
            robot.substate=nil
            robot.timer=nil
          end
        end
      end
    elseif (robot.state==jobType.JobDone) then --Job done message
      if (robot.substate==nil) then

        modem.transmit(basechannel, robot.robotchannel, textutils.serialize(robot.job.message))

        robot.timer = os.startTimer(timeout)
        robot.substate = 1
      elseif (robot.substate==1) then
        if (ev[1]=="modem_message") then
          local message=textutils.unserialize(ev[5])
          if (message.target == os.getComputerID() ) then
            if (message.request=="job_done_response") then
              print("job accept response received")
              robot.timer=nil
              robot.state=jobType.Home
              robot.substate=nil
            end
          end
        elseif (ev[1]=="timer") then
          if (ev[2]==robot.timer) then
            robot.substate=nil
            robot.timer=nil
          end
        end
      end
    end
  end
end

function DoWork()
  print("STARTING DoWork thread")
  while (true) do
    ev = {os.pullEventRaw()}

    --CHECK FUEL LEVEL EACH TIME
    --Needed because treechoping doesn't check if there is enough fuel
    if (turtle.getFuelLevel()~="unlimited" and turtle.getFuelLevel()<reserveFuel) then
      turtle.select(16)
      turtle.refuel(1)
    end

    if (robot.state==jobType.Home) then

      -- Get info about inventory

      local inv=turtle.getItemDetail(13) -- Dirt
      if (inv~=nil and Dirt[inv.name]) then  robot.dirt=inv.count
      else robot.dirt=0  end

      inv=turtle.getItemDetail(14) -- Torch
      if (inv~=nil and Torch[inv.name]) then  robot.torch=inv.count
      else robot.torch=0  end

      inv=turtle.getItemDetail(15) -- Sapling
      if (inv~=nil and Sapling[inv.name]) then  robot.sapling=inv.count
      else robot.sapling=0  end

      -- End


      if (robot.substate==2 and robot.location>0) then
        if (robot.to.go==false and lain.tcomparecord(robot,robot.to))then
          print("PICKING ITEMS FROM CHEST")
          local lookuptable,input,position=nil,nil,nil
          if (robot.location==1) then -- WOODC
            lookuptable,input,position=Wood,false,nil
          elseif (robot.location==2) then --SAPLINGC
            lookuptable,input,position=Sapling,true,15
          elseif (robot.location==3) then -- FUELC
            lookuptable,input,position=Fuel,true,16
          elseif (robot.location==4) then -- TorchC
            lookuptable,input,position=Torch,true,14
          elseif (robot.location==5) then -- DirtC
            lookuptable,input,position=Dirt,true,13
          end

          for i=1,16 do
            turtle.select(i)
            local invent=turtle.getItemDetail()
            if (invent~=nil and lookuptable[invent.name]) then
              turtle.dropDown()
            end
          end

          if (input) then
            turtle.select(position)
            turtle.suckDown(32)
          end

          turtle.select(1)
          robot.nextlocation = true
        elseif (robot.to.go==false) then -- IF there was a restart and robot not going to target
            robot.location = robot.location-1
            robot.nextlocation = true
        end
      end

      -- SEARCHING FOR JOB
      if (robot.jobqueue and #robot.jobqueue>0) then
        print("Removing jobqueue")


        -- Checking fuel level
        local fueldata = turtle.getItemDetail(16)

        if (turtle.getFuelLevel()=="unlimited") then
          robot.fuel=1000000000 --infinity
        elseif (fueldata~=nil) and (Fuel[fueldata.name]) then
            robot.fuel=Fuel[fueldata.name]*fueldata.count
            + turtle.getFuelLevel()
            - reserveFuel
        else
            robot.fuel= turtle.getFuelLevel() - reserveFuel
        end


          -- Analyzing job requests (accept, discard)
          while (robot.jobqueue and #robot.jobqueue>0) do
              local queuedjob = table.remove(robot.jobqueue,1)
              local accepted = false

              local remainingfuel = robot.fuel
              - lain.tdistance(robot,queuedjob.job.cord)
              - lain.tdistance(queuedjob.job.cord, robot.woodc)

              if (remainingfuel > 0) then
                  if (queuedjob.job.jobt == jobType.Dirt) then
                      local invent = turtle.getItemDetail(13)
                      if (invent~=nil and Dirt[invent.name]) then
                          accepted=true
                      end
                  elseif (queuedjob.job.jobt == jobType.Torch) then
                      local invent = turtle.getItemDetail(14)
                      if (invent~=nil and Torch[invent.name]) then
                          accepted=true
                      end
                  elseif (queuedjob.job.jobt == jobType.Sapling) then
                      local invent = turtle.getItemDetail(15)
                      if (invent~=nil and Sapling[invent.name]) then
                          accepted=true
                      end
                  elseif (queuedjob.job.jobt == jobType.Tree) then
                      accepted=true
                  end

                  if (accepted) then
                      robot.to.go=false
                      robot.job=queuedjob.job
                      robot.state=jobType.JobAccept
                      robot.substate=nil
                      robot.jobqueue={}
                  end
              end
          end
      end
    elseif (robot.state==jobType.Tree) then  -- CHOPING TREE
      if (robot.substate==0) then
        if (lain.tcomparecord(robot,robot.to)) then
          print("CHECKING IF TREE HAS GROWN")
          local block, blockdata = turtle.inspectDown()
          if (block) then
            if (Wood[blockdata.name]~=true) then
              -- This tree hasnt grow
              robot.substate=3
            else
              robot.substate=1
              print("CHOPING TREE UP")
            end
          else
            robot.substate=3 -- CANT FIND SAPLING ???? or root
          end
        else
          robot.substate=nil -- Try again
        end
      elseif (robot.substate==1) then
        if (robot.chopUP) then
          local block, blockdata = turtle.inspectUp()
          if (block) then
            if (Wood[blockdata.name]) then
              turtle.digUp()
              if (lain.tup()) then
                robot.subheight = robot.subheight + 1
              end
            else
              robot.chopUP=false
            end
          else
            print("CHOPPING TREE DOWN")
            robot.chopUP=false
          end
        else
          if (robot.subheight>0) then
            if (lain.tdown()) then
              robot.subheight = robot.subheight - 1
            end
          elseif (robot.subheight==0) then
            print("DESTROYING TREE BASE")
            local block, blockdata = turtle.inspectDown()
            if (block) then
              if (Wood[blockdata.name]) then
                turtle.digDown()
              end
            else
              print("RETURNING TO SENDING DONE MESSAGE")
              robot.substate=2
            end
          end
        end
      end
    elseif (robot.state==jobType.Torch or robot.state==jobType.Dirt or robot.state==jobType.Sapling) then 
      -- PLACE TORCH / DIRT / SAPLING
      if (robot.substate==1) then
        if (lain.tcomparecord(robot,robot.to)) then
            local lookuptable, slot
            if (robot.state==jobType.Torch) then
              lookuptable, slot = Torch, 14
              print("PLACING TORCH")
            elseif (robot.state==jobType.Dirt) then
              lookuptable, slot = Dirt, 13
              print("PLACING DIRT")
            elseif (robot.state==jobType.Sapling) then
              lookuptable, slot = Sapling, 15
              print("PLACING SAPLING")
            end

          local block, blockdata = turtle.inspectDown()
          if (block~=true) then
            turtle.select(slot)
            if (turtle.placeDown()) then
              robot.substate = robot.substate + 1
            end
            turtle.select(16)
          elseif (lookuptable[blockdata.name]) then
            robot.substate = robot.substate + 1
          end
        else
          robot.substate=nil --try again
        end
      end
    end
  end
end

jobType={
--- PASTED FROM CONTROL.LUA
  Dirt=5,
  Sapling=6,
  Torch=4,
  Tree=3,
--- worker.lua jobType
  Home=1,
  JobDone=8,
  JobAccept=7,
}

modem = peripheral.wrap(modemSide)
if (modem==nil) then
  print("ERROR modem")
  exit()
end


lain.addAllowedToBreak("minecraft:leaves")
for name,nn in pairs(Wood) do
  lain.addBlockTest(name,FoundTree)
end

term.clear()

parallel.waitForAny(lain.RobotMoveTo, TurtleTreeFarm,
lain.turtleUpdate, DoWork)

--[[
ccontrol = lain.CoroutineControl:new()
--ccontrol:addCoroutine(lain.RobotMoveTo)  -- automatic moving robot.to
ccontrol:addCoroutine(TurtleTreeFarm,{nil,modem})
--ccontrol:addCoroutine(lain.turtleUpdate)
--ccontrol:addCoroutine(DoWork)

ccontrol:loop()
]]--

