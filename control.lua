os.loadAPI("lain")
data={}

-- CONFIG --
basechannel=666 -- Modem channel where control computer listens for messages

modemSide= "right"
monitorSide = "back"
treeGrowWaitTimeInMinutes = 10
-- CONFIG END --

timeout = 2  -- TIME COUNTER TIMER
jobtimeout = 2
treeChopTime = treeGrowWaitTimeInMinutes*60/timeout


-- Function for screen with executed job output
function TurtleTreeFarmScreen(parentscreen)
  if (parentscreen==nil) then return 0 end

  local w,h=parentscreen.getSize()
  local screen = window.create(parentscreen, 1,1,w,h,true )

  while (true) do
    lain.Decorate(screen)
    screen.setCursorPos(5,1)
    screen.write("- Tree Farm - time ")
    screen.write(data.time)
    screen.write(" * ")
    screen.write(timeout)

    local i=3
    for id,bot in pairs(data.turtle) do
      screen.setCursorPos(3,i)
      screen.write(id)
      screen.write(" ")
      screen.write(bot.robot.state)
      screen.write(" ")
      if (bot.lastping==nil) then bot.lastping=0 end
      screen.write(data.time-bot.lastping)
      i=i+1
    end
    i=3
    j=20
    for id,job in pairs(data.jobqueue) do
      if (job.exec) then
        screen.setCursorPos(j,i)
        screen.write("# ")
        screen.write(job.exec)
        screen.write(" ")
        screen.write(job.jobt)
        screen.write(" ")
        screen.write(job.time)
        screen.write(" ")
        screen.write(job.asked)
        i=i+1
        if (i>=h) then
          i=3
          j=j+20
        end
      end
    end
    sleep(4)
  end
end

-- Main treefarm control function
function TreeFarmControl(parentscreen, modem)
  modem.closeAll()

  if (parentscreen==nil) then
    parentscreen=term.current()
  end

  local w,h=parentscreen.getSize()
  local screen = window.create(parentscreen, 3,3,w-3,h-3,true )

  data = lain.readData("base.log")

  if (data==nil) then
    data={}

    -- initializing farm
    data.farm = {}
    data.farm.x = lain.ReadUserInput(
    screen, "Tree farm starting block x?",true)

    data.farm.y = lain.ReadUserInput(
    screen, "Tree farm starting block y?",true)

    data.farm.z = lain.ReadUserInput(
    screen, "Tree farm starting block z?",true)

    data.farm.f = lain.ReadUserInput(
    screen, "Tree farm starting block f?",true)

    data.farm.pLength = lain.ReadUserInput(
    screen, "Farm sector count forward?",true)

    data.farm.nLength = -lain.ReadUserInput(
    screen, "Farm sector count back?",true)

    data.farm.pWidth = lain.ReadUserInput(
    screen, "Farm sector count left?",true)

    data.farm.nWidth = - lain.ReadUserInput(
    screen, "Farm sector count right?",true)

    data.jcnt=0
    data.jobqueue={}

    data.tcnt=0
    data.turtle = {}
    data.time = 0

    -- Initializing chest location
    data.saplingcLocal = {
      x=2,
      y=0,
      z=1
    }
    data.fuelcLocal = {
      x=4,
      y=0,
      z=1
    }
    data.woodcLocal = {
      x=0,
      y=0,
      z=1
    }
    data.torchcLocal = {
      x=6,
      y=0,
      z=1
    }
    data.dirtcLocal = {
      x=8,
      y=0,
      z=1
    }
    data.saplingc=lain.taddCord(data.farm, data.saplingcLocal)
    data.fuelc=lain.taddCord(data.farm, data.fuelcLocal)
    data.woodc=lain.taddCord(data.farm, data.woodcLocal)
    data.torchc=lain.taddCord(data.farm, data.torchcLocal)
    data.dirtc=lain.taddCord(data.farm, data.dirtcLocal)

    -- Creating job list (jobs to do)
    for i=data.farm.nWidth,data.farm.pWidth do
      for j=data.farm.nLength,data.farm.pLength do
        print("A55 ",i," ",j)
        if (j~=0) then   -- BECAUSE 0 row dont exist
          local job1 = {
            id=data.jcnt,
            x=(i*3),
            y=2,
            z=(j*4),
            jobt=jobType.Dirt,
            nextjob=jobType.Sapling,
            time=data.time
          }
          data.jcnt =  data.jcnt+1
          table.insert(data.jobqueue, job1)
          local job2 = {
            id=data.jcnt,
            x=(i*3),
            y=2,
            z=(j*4) + ((j>0) and (1) or (-1)),
            jobt=jobType.Dirt,
            nextjob=jobType.Torch,
            time=data.time
          }
          data.jcnt =  data.jcnt+1
          table.insert(data.jobqueue, job2)
          local job3 = {
            id=data.jcnt,
            x=(i*3),
            y=2,
            z=(j*4) + ((j>0) and (2) or (-2)),
            jobt=jobType.Dirt,
            nextjob=jobType.Sapling,
            time=data.time
          }
          data.jcnt =  data.jcnt+1
          table.insert(data.jobqueue, job3)
        end
      end
    end

    print("saving installation data")
    lain.writeData("base.log",data)
  end

  modem.open(basechannel) -- treefarm main channel

  -- Cleaning job requests timers from previous restart
  for it,job in pairs(data.jobqueue) do
    if (job.exec~=true and job.timeout~=nil) then
      job.timeout=nil
      data.turtle[job.asked].notfree=false
      break
    end
  end


  --Counter for timers
  local counter=os.startTimer(timeout)

  print("starting tree farm")
  local ev = {}

  while (true) do
    if (ev[1]=="timer") then
      if (ev[2]==counter) then
        data.time = data.time +1
        counter = os.startTimer(timeout)
      else
        -- CHECK IF WORK REQUEST WASN'T ACCEPTED
        for it,job in pairs(data.jobqueue) do
          if (job.exec~=true and job.timeout==ev[2]) then
            job.timeout=nil
            data.turtle[job.asked].notfree=false
            break
          end
        end
      end
    elseif (ev[1]=="modem_message") then
      local message = textutils.unserialize( ev[5] )
      if (message~=nil and message.request~=nil) then

        -- regular update about turtle state
        if (message.request=="ping") then
          -- print("PING MESSAGE ",message.ID)
          if (data.turtle[message.ID]~=nil) then
            data.turtle[message.ID].robot=message.robot;
            data.turtle[message.ID].lastping=data.time
            data.turtle[message.ID].responseCh=ev[4]

            if (message.robot.state==1) then  -- Robot is FREE
              --Trying to search for job
              local robo=data.turtle[message.ID]
              if (robo~=nil and robo.notfree~=true
                and robo.robot~=nil
                and robo.robot.state==1) then

                local minjob=nil
                for it, job in pairs(data.jobqueue) do
                  job.cord=lain.taddCord(data.farm, job)

                  if (job.exec~=true and job.timeout==nil
                    and data.time>=job.time) then

                    -- Check if robot inventory has requested materials
                    if (job.jobt==jobType.Dirt and robo.robot.dirt>0)
                      or (job.jobt==jobType.Torch and robo.robot.torch>0)
                      or (job.jobt==jobType.Sapling and robo.robot.saplings>0)
                      or (job.jobt==jobType.Tree) then

                      if (minjob==nil
                        or lain.tdistance(robo.robot,job.cord)
                        <lain.tdistance(minjob.cord,robo.robot)) then
                        minjob=job
                      end
                    end
                  end
                end
                if (minjob~=nil) then -- SEND JOB REQUEST
                  minjob.timeout=os.startTimer(jobtimeout)
                  local response = {
                    target = robo.ID,
                    request = "job",
                    job = minjob,
                  }
                  robo.notfree=true
                  minjob.asked=robo.ID
                  print("Sending job request ",jobTypeName[minjob.jobt]," to ",response.target)

                  modem.transmit(
                  robo.responseCh,basechannel,textutils.serialize(response))

                end
              end
            end
          end
        elseif (message.request=="startup") then
          print("STARTUP request")
          if (data.turtle[message.ID]==nil) then
            --NEED TO CALCULATE TURTLE HOME position
            data.turtle[message.ID]={}
            data.turtle[message.ID].homeLocal={
              x=data.tcnt,
              y=0,
              z=-1,
            }
            data.turtle[message.ID].ID = message.ID
            data.turtle[message.ID].robot = {}
            data.tcnt = data.tcnt + 1

            data.turtle[message.ID].home=lain.taddCord(
            data.farm, data.turtle[message.ID].homeLocal)

          end
          data.turtle[message.ID].robot.x=message.robot.x
          data.turtle[message.ID].robot.y=message.robot.y
          data.turtle[message.ID].robot.z=message.robot.z
          data.turtle[message.ID].robot.f=message.robot.f
          data.turtle[message.ID].responseCh=ev[4]
          data.turtle[message.ID].robot.state=message.robot.state

          local response = {
            target = message.ID,
            request = "startup",
            home = data.turtle[message.ID].home,
            saplingc = data.saplingc,
            fuelc = data.fuelc,
            woodc = data.woodc,
            torchc = data.torchc,
            dirtc = data.dirtc
          }
          modem.transmit(
          data.turtle[message.ID].responseCh,basechannel,
          textutils.serialize(response))

          -- TURTLE IS GOING TO DO A JOB
        elseif (message.request=="accepted") then
          print("Job accept request from ",message.ID)
          local accept_fail=true
          for it,job in pairs(data.jobqueue) do
            if (job.id == message.jobid and job.exec~=true) then
              data.turtle[message.ID].notfree=false
              job.exec=true
              job.timeout=nil
              local response = {
                target = message.ID,
                request = "accepted_response",
              }
              modem.transmit(data.turtle[message.ID].responseCh,basechannel,
              textutils.serialize(response))

              accept_fail = false
            end
          end

          if (accept_fail) then
            local response = {
              target = message.ID,
              request = "accepted_response_fail",
            }
            modem.transmit(data.turtle[message.ID].responseCh,basechannel,
            textutils.serialize(response))
          end

        elseif (message.request=="job_done") then  -- TURTLE FINISHED JOB
          print("job done request from ",message.ID)

          local response = {
            target = message.ID,
            request = "job_done_response",
          }
          modem.transmit(data.turtle[message.ID].responseCh,basechannel,
          textutils.serialize(response))

          for it, job in pairs(data.jobqueue) do
            if (job.id==message.jobid) then
              data.turtle[message.ID].notfree=false
              if (job.jobt == jobType.Tree) then
                if (message.jobstatus == "DONE" ) then
                  job.exec=false
                  job.jobt=jobType.Sapling
                  job.time=data.time
                  job.timeout=nil
                elseif (message.jobstatus == "NOT GROWN") then
                  job.exec=false
                  job.time=data.time+(treeChopTime)
                  job.timeout=nil
                end
              elseif (job.jobt == jobType.Torch) then
                if (message.jobstatus == "TORCH") then
                  table.remove(data.jobqueue,it)
                end
              elseif (job.jobt == jobType.Dirt) then
                if (message.jobstatus == "DIRT") then
                  job.exec=false
                  job.time=data.time
                  job.y= job.y + 1
                  job.jobt = job.nextjob
                  job.timeout=nil
                end
              elseif (job.jobt == jobType.Sapling) then
                if (message.jobstatus == "SAPLING") then
                  job.exec = false
                  job.time=data.time + treeChopTime
                  job.jobt = jobType.Tree
                  job.timeout=nil
                end
              end

              break
            end
          end

        end
      end
    end

    lain.writeData("base.log",data)
    ev = { os.pullEventRaw()}
  end
end

--[[
--
--
-- Start of main program
--
--
--
--]]
jobType={
  Dirt=5,
  Sapling=6,
  Torch=4,
  Tree=3
}

jobTypeName={
  [jobType.Dirt] = "Dirt",
  [jobType.Sapling] = "Sapling",
  [ jobType.Torch ] = "Torch",
  [ jobType.Tree ] = "ChopTree",
}

monitor = peripheral.wrap(monitorSide)
if (monitor~=nil) then
  monitor.setTextScale(0.5)
end

modem = peripheral.wrap(modemSide)
if (modem==nil) then
  print("Modem must be attached at the right side of computer")
  exit()
end

--term.redirect(peripheral.wrap("top"))

term.clear()

ccontrol = lain.CoroutineControl:new()
--ccontrol:addCoroutine(lain.DisplayEvents, {monitor})
ccontrol:addCoroutine(TreeFarmControl, {term.current(), modem})
ccontrol:addCoroutine(TurtleTreeFarmScreen, {monitor})

ccontrol:loop()

