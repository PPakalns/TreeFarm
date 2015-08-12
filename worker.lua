os.loadAPI("lain")

basechannel = 666
robotchannel = 777
modemSide="left"

timeout = 5
refreshtimer = 30
pingtimer=15

Wood = {
	[ "minecraft:log" ]=true,
	[ "IC2:blockRubWood" ]=true,
	[ "minecraft:leaves" ]=true
}

Saplings = {
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
	[ "minecraft:coal" ]=true,
	[ "minecraft:coal_block" ]=true
}

function FoundTree(cordinate) -- Continue, allowtobreak, return
	if (lain.tcomparecord(cordinate, robot.to)) then
		return true, true, nil
	else
		return true, false, nil
	end
end

function Ping()
	local message = {
		ID = os.getComputerID(),

		robot = {
			x=robot.x,
			y=robot.y,
			z=robot.z,
			f=robot.f,
			state=robot.state,
		},
		request="ping"
	}
	modem.transmit(basechannel, robotchannel, textutils.serialize(message) )
end

function TurtleTreeFarm(parentscreen, modem, robot)
	print("yolo")
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
	modem.open(777)

	local ping = os.startTimer(pingtimer)
	local refresh = os.startTimer(refreshtimer)
	local hometimer=nil

	print("STARTING TURTLE TREE FARM")
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
				modem.transmit(basechannel, robotchannel, textutils.serialize(message))
				robot.timer = os.startTimer(timeout)
				robot.substate=1
			elseif (robot.substate==1) then
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
							robot.state=1
							robot.substate=nil
							robot.jobqueue={}
						end
					end
				elseif (ev[1]=="timer") then
					if (ev[2]==robot.timer) then
						robot.substate=0
					end
				end
			end

		elseif (robot.state==1) then -- GOING HOME
			if (robot.substate==nil or robot.substate==-2) then
				Ping() -- UPDATE STATE
				ping=os.startTimer(pingtimer)

				hometimer=os.startTimer(2)
				robot.substate=-1
			elseif (robot.substate==-1) then
				if (ev[1]=="timer") then
					if (ev[2]==hometimer) then
						robot.substate=0
					end
				end
			elseif (robot.substate==0) then
				print("GOING HOME")
				robot.jobqueue={}
				robot.to={}
				robot.to.go, robot.to.calculated = true, false
				lain.tpasteCord(robot.woodc,robot.to)  -- MOVE TO WOODC
				robot.substate=1
			elseif (robot.substate==1) then
				if (lain.tcomparecord(robot.to,robot)) then
					print("INVENTORY STATE")
					robot.to.go=false
					robot.substate=2
				end
			elseif (robot.substate==3) then
				robot.to.go, robot.to.calculated = true, false
				lain.tpasteCord(robot.saplingc,robot.to)  -- MOVE TO SAPLINGC
				robot.substate=4
			elseif (robot.substate==4) then
				if (lain.tcomparecord(robot.to,robot)) then
					robot.to.go=false
					robot.substate=5
				end
			elseif (robot.substate==6) then
				robot.to.go, robot.to.calculated = true, false
				lain.tpasteCord(robot.fuelc,robot.to)  -- MOVE TO FUELC
				robot.substate=7
			elseif (robot.substate==7) then
				if (lain.tcomparecord(robot.to,robot)) then
					robot.to.go=false
					robot.substate=8
				end
			elseif (robot.substate==9) then
				robot.to.go, robot.to.calculated = true, false
				lain.tpasteCord(robot.torchc,robot.to)  -- MOVE TO torchc
				robot.substate=10
			elseif (robot.substate==10) then
				if (lain.tcomparecord(robot.to,robot)) then
					robot.to.go=false
					robot.substate=11
				end
			elseif (robot.substate==12) then
				robot.to.go, robot.to.calculated = true, false
				lain.tpasteCord(robot.dirtc,robot.to)  -- MOVE TO dirtc
				robot.substate=13
			elseif (robot.substate==13) then
				if (lain.tcomparecord(robot.to,robot)) then
					robot.to.go=false
					robot.substate=14
				end
			elseif (robot.substate==15) then
				robot.to.go, robot.to.calculated = true, false
				lain.tpasteCord(robot.home,robot.to)  -- MOVE TO home
				robot.substate=16
			elseif (robot.substate==16) then
				if (lain.tcomparecord(robot.to,robot)) then
					robot.to.go=false
					robot.substate=17
				end
			elseif (robot.substate==17) then
				print(" HOME ")
				-- HOME
			end

			if (ev[1]=="modem_message") then
				local message=textutils.unserialize(ev[5])
				if (message.request=="job" and message.target==robot.id) then
					table.insert(robot.jobqueue,message)
				end
			end
		elseif (robot.state==3) then -- ChopingTree
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
				robot.state=8
				robot.job.message=message

			elseif (robot.substate==3) then
				-- Tree didnt grow
				local message = {
					ID = os.getComputerID(),
					request="job_done",
					jobid = robot.job.id,
					jobstatus = "NOT GROWN"
				}

				robot.subheight=nil
				robot.chopUP=nil
				robot.substate=nil
				robot.state=8
				robot.job.message=message
			end
		elseif (robot.state==4) then -- Torch
			if (robot.substate==nil) then
				print("Placing torch")
				robot.substate=0
				lain.tpasteCord(robot.job.cord, robot.to)
				robot.to.go, robot.to.calculated = true, false
			end

			if (robot.substate==0 and lain.tcomparecord(robot, robot.to)) then
				robot.go = false
				robot.substate=1  -- state place torch
			end

			if (robot.substate==2) then -- torch placed
				local message = {
					ID = os.getComputerID(),
					request="job_done",
					jobid = robot.job.id,
					jobstatus = "TORCH"
				}

				robot.substate=nil
				robot.state=8
				robot.job.message=message
			end

		elseif (robot.state==5) then -- Dirt
			if (robot.substate==nil) then
				print("Placing dirt")
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
					jobstatus = "DIRT"
				}

				robot.substate=nil
				robot.state=8
				robot.job.message=message
			end
		elseif (robot.state==6) then -- Sapling
			if (robot.substate==nil) then
				print("Placing sapling")
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
					jobstatus = "SAPLING"
				}

				robot.substate=nil
				robot.state=8
				robot.job.message=message
			end
		elseif (robot.state==7) then -- Accepting job
			if (robot.substate==nil) then
				local message = {
					ID = os.getComputerID(),
					request = "accepted",
					jobid= robot.job.id,
				}
				modem.transmit(basechannel, robotchannel, textutils.serialize(message))
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
							robot.state=1
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
		elseif (robot.state==8) then
			if (robot.substate==nil) then
				modem.transmit(basechannel, robotchannel, textutils.serialize(robot.job.message))
				robot.timer = os.startTimer(timeout)
				robot.substate = 1
			elseif (robot.substate==1) then
				if (ev[1]=="modem_message") then
					local message=textutils.unserialize(ev[5])
					if (message.target == os.getComputerID() ) then
						if (message.request=="job_done_response") then
							print("job accept response received")
							robot.timer=nil
							robot.state=1
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
		if (robot.state==1) then

			if (robot.substate==2 or robot.substate==5 or robot.substate==8 or robot.substate==11 or robot.substate==14) then
				if (lain.tcomparecord(robot,robot.to))then
					print("PICKING ITEMS FROM CHEST")
					local lookuptable,input,position=nil,nil,nil
					if (robot.substate==2) then -- WOODC
						lookuptable,input,position=Wood,false,nil
					elseif (robot.substate==5) then --SAPLINGC
						lookuptable,input,position=Saplings,true,15
					elseif (robot.substate==8) then -- FUELC
						lookuptable,input,position=Fuel,true,16
					elseif (robot.substate==11) then -- TorchC
						lookuptable,input,position=Torch,true,14
					elseif (robot.substate==14) then
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
					robot.substate=robot.substate+1
				else
					robot=robot.substate-2 --REset
				end
			end

			-- SEARCHING FOR JOB
			if (robot.jobqueue and #robot.jobqueue>0) then
				print("Removing jobqueue")
				-- CHECK FUEL

				local message = table.remove(robot.jobqueue,1)
				if (message.job.jobt == jobType.Dirt) then
					local invent = turtle.getItemDetail(13)
					if (invent~=nil) then
						if (Dirt[invent.name]) then
							robot.to.go=false
							robot.job=message.job
							robot.state=7
							robot.substate=nil
							robot.jobqueue={}
						end
					end
				elseif (message.job.jobt == jobType.Torch) then
					local invent = turtle.getItemDetail(14)
					if (invent~=nil) then
						if (Torch[invent.name]) then
							robot.to.go=false
							robot.job=message.job
							robot.state=7
							robot.substate=nil
							robot.jobqueue={}
						end
					end

				elseif (message.job.jobt == jobType.Sapling) then
					local invent = turtle.getItemDetail(15)
					if (invent~=nil) then
						if (Saplings[invent.name]) then
							robot.to.go=false
							robot.job=message.job
							robot.state=7
							robot.substate=nil
							robot.jobqueue={}
						end
					end

				elseif (message.job.jobt == jobType.Tree) then
					robot.to.go=false
					robot.job=message.job
					robot.state=7
					robot.substate=nil
					message.jobqueue={}
				end
			end
		elseif (robot.state==3) then  -- CHOPING TREE
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
		elseif (robot.state==4) then --Torch
			if (robot.substate==1) then
				if (lain.tcomparecord(robot,robot.to)) then
					print("PLACING TORCH")
					local block, blockdata = turtle.inspectDown()
					if (block~=true) then
						turtle.select(14)
						if (turtle.placeDown()) then
							robot.substate = robot.substate + 1
						end
						turtle.select(1)
					elseif (Torch[blockdata.name]) then
						robot.substate = robot.substate + 1
					end
				else
					robot.substate=nil --try again
				end
			end
		elseif (robot.state==5) then --Dirt
			if (robot.substate==1) then
				if (lain.tcomparecord(robot,robot.to)) then
					print("PLACING DIRT")
					local block, blockdata = turtle.inspectDown()
					if (block~=true) then
						turtle.select(13)
						if (turtle.placeDown()) then
							robot.substate = robot.substate + 1
						end
						turtle.select(1)
					elseif (Dirt[blockdata.name]) then
						robot.substate = robot.substate + 1
					end
				else
					robot.substate=nil --try again
				end
			end
		elseif (robot.state==6) then --sapling
			if (robot.substate==1) then
				if (lain.tcomparecord(robot,robot.to)) then
					print("PLACING SAPLING")
					local block, blockdata = turtle.inspectDown()
					if (block~=true) then
						turtle.select(15)
						if (turtle.placeDown()) then
							robot.substate = robot.substate + 1
						end
						turtle.select(1)
					elseif (Saplings[blockdata.name]) then
						robot.substate = robot.substate + 1
					end
				else
					robot.substate=nil --try again
				end
			end
		end
	end
end


--- PASTED FROM CONTROL.LUA
jobType={
	Dirt=5,
	Sapling=6,
	Torch=4,
	Tree=3
}
--END
modem = peripheral.wrap(modemSide)
if (modem==nil) then
	print("ERROR")
	exit(0)
end

robot = lain.robot

lain.addAllowedToBreak("minecraft:leaves")
for name,nn in pairs(Wood) do
	lain.addBlockTest(name,FoundTree)
end

term.clear()

--TurtleTreeFarm(nil,modem)

parallel.waitForAny(lain.RobotMoveTo, TurtleTreeFarm, lain.turtleUpdate, DoWork)
--[[
ccontrol = lain.CoroutineControl:new()
--ccontrol:addCoroutine(lain.RobotMoveTo)  -- automatic moving robot.to
ccontrol:addCoroutine(TurtleTreeFarm,{nil,modem})
--ccontrol:addCoroutine(lain.turtleUpdate)
--ccontrol:addCoroutine(DoWork)

ccontrol:loop()
]]--

