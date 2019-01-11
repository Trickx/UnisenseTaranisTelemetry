-- ######################################################
-- ## Script by Ollicious,  bowdown@gmx.net            ##
-- ## V 1.0, 2015/09/15                                ##
-- ## -------------------------------------------------##
-- ## edit by Dirk Wesenberg, 2017/09/28               ##
-- ## DeWe (http://www.kopterforum.at)				   ##
-- ## -------------------------------------------------##
local WgtDefinition = {{"batteryh","rssih"},{"hp","dummy","radar"},{"current","gps","timer"},{"fmAr","dummy","IFT"},{"GPSheight", "dist","speed"}} -- Arduino
--local WgtDefinition = {{"battery"},{"dummy", "CAmp","current"},{"fmBF", "Altheight", "timer"},{"dummy","dummy","IFT"},{"rssi"}}--for Boris	
--
local battype 				-- dont Support 5s&7s Battery
-- Leave as is!
local xOffsetSingle = 35 	-- Edit to set the width of single Wgt columns
local displayWidth = 212
local displayHeight = 64
local xOffset
local xOffsetMulti
local numSingleCols
local numMultiCols
local myMaxV
local myMinV
local mincell
local myNumSat                                
local myQualSat                                 
local HomeAlt 
local set_prearm
local prearmheading
local pilotlat
local pilotlon
local gpsLatLon = {}
local LocationLat = 0
local LocationLon = 0
local CenterXcolArrow
local CenterYrowArrow
local sinCorr
local cosCorr
local divtmp
local last_pos_lat
local last_pos_lon
local oldTime
local Time
local lastsay
local compare
local totalbatteryComsum
local noMove
local home_set
local last_fly_mode
local HV_Lipo
local F_Roll
-- Rounding --
local function rnd(v,d)
	if d then
	 return math.floor((v*10^d)+0.5)/(10^d)
	else
	 return math.floor(v+0.5)
	end
end
-- Telemetry ID --
local function getTelemetryId(name)
	field = getFieldInfo(name)
	if field then
	  return field.id
	else
	  return -1
	end
end
-- Get Value --
local function getVDef(value)
	local tmp = getValue(value)
	
	if tmp == nil then
		return 0
	end
	
	return tmp
end
-- Flugmode Wgt;			MULTI Row Wgt --
local function fmWgt(xCoord, yCoord,FC_type)  
		
	local FM_Tmp1 = getVDef("Tmp1")
	local conFMo = "NoTlm"
	
	lcd.drawPixmap(xCoord + 1, yCoord + 2, "/SCRIPTS/TELEMETRY/OLIME/fm.bmp") 
	if ((getTelemetryId("Tmp1") == -1) or (getVDef("RSSI") < 20)) then
						  conFMo = "NoTlm"	
	else
		if (FM_Tmp1 < 100000) and (FM_Tmp1 >= 0) then
			local FiveDigit = math.floor(FM_Tmp1 / 10000)
			local FourDigit = math.floor ((FM_Tmp1 % 10000) / 1000)
			local ThreeDigit = math.floor((FM_Tmp1 % 1000) / 100) 
			local TwoDigit = math.floor((FM_Tmp1 % 100) / 10)
			local OneDigit = math.floor(FM_Tmp1 % 10)
			
				if (OneDigit == 0) then
						conFMo = "Manu" 
					elseif (OneDigit == 1) then
						conFMo = "GPSH"
					elseif (OneDigit == 2) then	
						conFMo = "FailS"
					elseif (OneDigit == 3) then	
						conFMo = "Attitude"
					else
						conFMo = "Unkwn"
				end
		end		
	end
		local Disp_FM = string.sub(conFMo,1, 5)
		lcd.drawText(xCoord + 18, yCoord + 7,Disp_FM, SMLSIZE)
		
	if last_fly_mode ~= conFMo then 
			playFile("/SCRIPTS/TELEMETRY/WAV/"..conFMo..".wav")					
		last_fly_mode = conFMo
	end
end
-- Dummy --
local function dummyWgt (xCoord, yCoord)	
	-- for 2 places 
end 
 -- IFT;    MULTI Row Col Wgt --
 local function IFTWgt(xPos, yPos,w_type)	

	local XH = 0
	local YH = 0
	local X1 = 0
	local X2 = 0
	local Y1 = 0
	local Y2 = 0

	CenterXcolArrow = xPos + 23 + numSingleCols
	CenterYrowArrow = yPos 
	lcd.drawText(xPos + 12 + numSingleCols, yPos-7,"-o-",MIDSIZE)	
	if (w_type > 1) then
	
--			local pitch = (getVDef("AccX") * 100 ) % 360
			local pitch = (getVDef("A4"))
			local roll 
--				roll = (getVDef("AccY") * 90) %360 
				roll = getVDef("A3")
					F_Roll = (F_Roll * 15 + roll)/16	
			local mapRatio = 0
			local radAH = 16 + numSingleCols
			local pitchR = radAH / 25
			local dPitch_1 = 0
			local dPitch_2 = 0
			local attAH = FORCE + GREY(10)
			local colAH = xPos + (xOffsetSingle/2) +3 + numSingleCols/ 2.5
			local rowAH = yPos
			local tanRoll = 0			
					roll = rnd(roll)
					
						if (roll == 90) then roll = 89 end
						if (roll == 270) then roll = 269 end				
			local sinRoll = math.sin(math.rad(-roll))
			local cosRoll = math.cos(math.rad(-roll))
					pitch = rnd(pitch)
					if (pitch < 70) then
						pitch = pitch / 3
					elseif (pitch > 290) then
						pitch = (360-((360- pitch)/3))	
					end  
				local delta = pitch % 15		
				  for i = delta - 30 , 30 + delta, 15 do	 
						XH = pitch == i % 360 and 23 or 13
						YH = pitchR * i
						
						X1 = -XH * cosRoll - YH * sinRoll
							X1 = rnd(X1)
						Y1 = -XH * sinRoll + YH * cosRoll
							Y1 = rnd(Y1)
						X2 = (XH - 2) * cosRoll - YH * sinRoll
							X2 = rnd(X2)
						Y2 = (XH - 2) * sinRoll + YH * cosRoll						
							Y2 = rnd(Y2)
						
							if not ( 
								 (X1 < -radAH and X2 < -radAH) 
							  or (X1 > radAH and X2 > radAH)  
							  or (Y1 < -radAH and Y2 < -radAH) 
							  or (Y1 > radAH and Y2 > radAH)  
							) then 

							 mapRatio = (Y2 - Y1) / (X2 - X1)
							  if X1 < -radAH then  Y1 = (-radAH - X1) * mapRatio + Y1 X1 = -radAH end
							  if X2 < -radAH then  Y2 = (-radAH - X1) * mapRatio + Y1 X2 = -radAH end
							  if X1 > radAH then  Y1 = (radAH - X1) * mapRatio + Y1 X1 = radAH end
							  if X2 > radAH then  Y2 = (radAH - X1) * mapRatio + Y1 X2 = radAH end

							 mapRatio = 1 / mapRatio
							  if Y1 < -radAH then  X1 = (-radAH - Y1) * mapRatio + X1 Y1 = -radAH end
							  if Y2 < -radAH then  X2 = (-radAH - Y1) * mapRatio + X1 Y2 = -radAH end
							  if Y1 > radAH then  X1 = (radAH - Y1) * mapRatio + X1 Y1 = radAH end
							  if Y2 > radAH then  X2 = (radAH - Y1) * mapRatio + X1 Y2 = radAH end

								lcd.drawLine(
								xPos + numSingleCols + math.floor(X1 + 0.5) + (xOffsetSingle/1.5)-1,
								yPos + math.floor(Y1 - 0.5),
								xPos + numSingleCols + math.floor(X2 + 0.5) + (xOffsetSingle/1.5)-4,
								yPos + math.floor(Y2 - 0.5),
								SOLID, FORCE)
							
							end
					end	
				
			dPitch_1 = pitch % 180
				if dPitch_1 > 90 then dPitch_1 = 180 - dPitch_1 end
				 cosRoll = math.cos(math.rad(roll))
				  if pitch > 270 then
					dPitch_1 = -dPitch_1 * pitchR / cosRoll
					dPitch_2 = radAH / cosRoll
				  elseif pitch > 180 then
					dPitch_1 = dPitch_1 * pitchR / cosRoll
					dPitch_2 = -radAH / cosRoll
				  elseif pitch > 90 then
					dPitch_1 = -dPitch_1 * pitchR / cosRoll
					dPitch_2 = -radAH / cosRoll
				  else
					dPitch_1 = dPitch_1 * pitchR / cosRoll
					dPitch_2 = radAH / cosRoll
				  end

			tanRoll = -math.tan(math.rad(roll))
			  for i = -radAH, radAH, 1 do
				YH = i * tanRoll
				Y1 = math.floor(YH + dPitch_1 + 0.5)
					if Y1 > radAH then
					  Y1 = radAH
					elseif Y1 < -radAH then
					  Y1 = -radAH
					end
				Y2 = math.floor(YH + 1.5 * dPitch_2 + 0.5)
					if Y2 > radAH then
					  Y2 = radAH 
					elseif Y2 < -radAH then
					  Y2 = -radAH
					end
				X1 = colAH + i + numSingleCols
							X1 = rnd(X1)
							X2 = rnd(X2)
							Y1 = rnd(Y1)
							Y2 = rnd(Y2)
					if Y1 < Y2 then
					  lcd.drawLine(X1, rowAH + Y1, X1, rowAH + Y2, SOLID, attAH)
					elseif Y1 > Y2 then
					  lcd.drawLine(X1, rowAH + Y2, X1, rowAH + Y1, SOLID, attAH)
					end
			  end  

	end			
		
	if (w_type < 3 ) then
	
	   local radarx = 0
	   local radary = 0
	   local radTmp = 0
	   local radarytmp = 0
	   local curlat = 0
	   local curlon = 0
	   local z1 = 0
	   local z2 = 0
	   local hypdist = 0
	   local offsetX = 0
	   local offsetY = 0
	   local radarxtmp = 0

										
		gpsLatLon = getVDef("GPS")
				if (type(gpsLatLon) == "table") then
					if gpsLatLon["lat"] ~= NIL then
						LocationLat = gpsLatLon["lat"]
					end
					if gpsLatLon["lon"] ~= NIL then
						LocationLon = gpsLatLon["lon"]
					end
				end

			if set_prearm then
					prearmheading = getVDef("Hdg")
						pilotlat = math.rad(LocationLat)
						pilotlon = math.rad(LocationLon)
					set_prearm = false
					home_set = true
			end

			curlat = math.rad(LocationLat)
			curlon = math.rad(LocationLon)
	
		if pilotlat~=0 and curlat~=0 and pilotlon~=0 and curlon~=0 then
		
			local upppp = 20480
			local divvv = 2048 --12 mal teilen
	   
			z1 = math.sin(curlon - pilotlon) * math.cos(curlat)
			z2 = math.cos(pilotlat) * math.sin(curlat) - math.sin(pilotlat) * math.cos(curlat) * math.cos(curlon - pilotlon)
			
			radarx=z1*6358364.9098634
			radary=z2*6358364.9098634
			
			hypdist =  math.sqrt( math.pow(math.abs(radarx),2) + math.pow(math.abs(radary),2) )
			radTmp = math.rad( prearmheading )
			radarxtmp = radarx * math.cos(radTmp) - radary * math.sin(radTmp)
			radarytmp = radarx * math.sin(radTmp) + radary * math.cos(radTmp)
			
			if math.abs(radarxtmp) >= math.abs(radarytmp) then 
				for i = 13 ,1,-1 do
					if math.abs(radarxtmp) >= upppp then
						divtmp=divvv
						break
					end
					divvv = divvv/2
					upppp = upppp/2
				end
			else
				for i = 13 ,1,-1 do				
					if math.abs(radarytmp) >= upppp then
						divtmp=divvv
						break
					end
					divvv = divvv/2
					upppp = upppp/2
				end
			end
			
			offsetX = radarxtmp / divtmp
			offsetY = (radarytmp / divtmp)*-1
		end

			for j= xPos + 2 , xPos +39, 4 do			
				lcd.drawPoint(j  + numSingleCols, yPos-1)
			end
			for j= yPos +2, yPos +39, 4 do 
				lcd.drawPoint(xPos+21 + numSingleCols, j-21) 				
			end

			lcd.drawNumber(xPos +22 + numSingleCols, yPos +16,hypdist, SMLSIZE+RIGHT)
			lcd.drawText(lcd.getLastPos(), yPos +16, "m", SMLSIZE)

		CenterXcolArrow = xPos + 21 + numSingleCols
		CenterYrowArrow = yPos 

		local arrowLine = {
		  { 0, -5, -4,  4},
		  {-4,  4,  0,  2},
		  { 0,  2,  4,  4},
		  { 4,  4,  0, -5}
		}			
			sinCorr = math.sin(math.rad(getVDef("Hdg")-prearmheading))
			cosCorr = math.cos(math.rad(getVDef("Hdg")-prearmheading))
			for index, point in pairs(arrowLine) do
				X1 = CenterXcolArrow + offsetX + math.floor(point[1] * cosCorr - point[2] * sinCorr + 0.5)
				Y1 = CenterYrowArrow + offsetY + math.floor(point[1] * sinCorr + point[2] * cosCorr + 0.5)
				X2 = CenterXcolArrow + offsetX + math.floor(point[3] * cosCorr - point[4] * sinCorr + 0.5)
				Y2 = CenterYrowArrow + offsetY + math.floor(point[3] * sinCorr + point[4] * cosCorr + 0.5)
				if X1 == X2 and Y1 == Y2 then
					lcd.drawPoint(X1, Y1, SOLID, FORCE)
				else
					lcd.drawLine (X1, Y1, X2, Y2, SOLID, FORCE)				
				end
			end

	end	
end
--  Lipo Cell Dection 
local function BattCT()
   
   local comp_1
   local comp_2
   
    if (battype==0) then
		if getVDef("RSSI") > 55 then
		
			comp_1 = getVDef("VFAS") 
				if comp_1 > 0 then
					comp_2 = getVDef("VFAS")
					if comp_1 == comp_2 then
						compare = compare + 1
					end
				end
 
				if compare > 40 then
					  if math.floor(comp_1/4.37) > battype and (comp_1 < (4.37*8)) then 
						 battype=math.ceil(comp_1/4.37)
						 if battype==7 then battype=8 end --dont Support 5s&7s Battery, its Danger to Detect
						 if battype==5 then battype=6 end 
					   end
				end
		end
	end
end
--  Lipo Cell Dection 
local function SayBattP(battpercent)  

  local sayS = 9
  
		if ((battpercent < 20) and (battpercent > 0)) then
			sayS = 1
		end
		 if battpercent < (lastsay-sayS) or battpercent > (lastsay+9) then 
			Time[6] = Time[6] + (getTime() - oldTime[6]) 				
			if Time[6]> 500 then 
				if sayS < 9 then
					lastsay = battpercent/1
				else
					lastsay=(rnd(battpercent*0.1)*10)
				end
					Time[6] = 0
					playNumber(lastsay, 13, 0)
			  if ((lastsay <= 30) and (lastsay > 20)) then 
				playFile("/SCRIPTS/TELEMETRY/WAV/BattS.wav") 
			  elseif ((lastsay <= 20) and (lastsay > 10))then 
				playFile("/SCRIPTS/TELEMETRY/WAV/BattK.wav") 
			  elseif lastsay <= 10 then
				 playFile("/SCRIPTS/TELEMETRY/WAV/BattA.wav")
			  end
			end  
			oldTime[6] = getTime()
		  else    
			Time[6] = 0
			oldTime[6] = getTime()
		  end

end
-- Current  	MULTI Row Col Wgt --
   local function totcWgt(xCoord, yCoord)
   
      Time[1] = Time[1] + (getTime() - oldTime[1])
      if Time[1] >=20 then --200 ms
        totalbatteryComsum  = totalbatteryComsum + ( getVDef("Curr") * (Time[1]/360))
        Time[1] = 0
		 oldTime[1] = getTime() 
      end
	  
		lcd.drawPixmap(xCoord + 2, yCoord + 2, "/SCRIPTS/TELEMETRY/OLIME/BattA1.bmp")
	    lcd.drawNumber(xCoord + 20, yCoord + 5,totalbatteryComsum , LEFT)
		lcd.drawText(xCoord + 23, yCoord + 13, "mAh", SMLSIZE)
	  
    end
-- Battery;     SINGLE Row Col Wgt --
local function battWgt(xCoord, yCoord,Fullwdgt)

	local battNorm = Fullwdgt
	local myPxHeight
	local myPxY
	local myCurrent = 0
	local myPercent = 0
	local offyCoord = yCoord
	local myAvailV = 0
	
	if (battype==0) then
		BattCT()
	end
	
		if battype > 0 then
		   myCurrent = getVDef("VFAS") * 10
					if (getVDef("Low") > 0) then
						mincell = (getVDef("Low") *10)
					elseif (getVDef("C1") > 0) then
						mincell = (getVDef("C1") * 10)
							if (getVDef("C2") > 0) and (getVDef("C2") * 10 < mincell) then
								mincell = (getVDef("C2") * 10)
							end 
							if (getVDef("C3") > 0) and (getVDef("C3") * 10 < mincell) then
								mincell = (getVDef("C3") * 10)
							end 
							if (getVDef("C4") > 0) and (getVDef("C4") * 10 < mincell) then
								mincell = (getVDef("C4") * 10)
							end 
							if (getVDef("C5") > 0) and (getVDef("C5") * 10 < mincell) then
								mincell = (getVDef("C5") * 10)
							end 
							if (getVDef("C6") > 0) and (getVDef("C6") * 10 < mincell) then
								mincell = (getVDef("C6") * 10)
							end 
					elseif (getVDef("Cell") > 0) then                
						mincell = getVDef("Cell") * 10
					elseif (getVDef("A4") > 0) then
						mincell = getVDef("A4") * 10
					else   
						mincell = (getVDef("VFAS")*10 / battype)
					end

				if ((myMinV == 0) and (myMaxV == 0))then
					myMaxV = math.floor(42 * battype)
					myMinV = math.floor(34 * battype)
				end
					
		   local myRangeV = myMaxV - myMinV 
				myAvailV = myCurrent - myMinV 
				myPercent = math.floor(myAvailV / myRangeV * 100)  
					if myPercent < 1 then
						myPercent = 0
					elseif (myPercent > 100 and HV_Lipo == false) then
						myMaxV = math.floor(44 * battype)
						myMinV = math.floor(36 * battype)		
						HV_Lipo = true
							myRangeV = myMaxV - myMinV 
								myAvailV = myCurrent - myMinV 
							myPercent = math.floor((myAvailV / myRangeV * 100)/1)
							playFile("/SCRIPTS/TELEMETRY/WAV/HvLipo.wav")		
					end

				SayBattP(myPercent)					
		end  
		 
		   if ((myAvailV == nil) or (myAvailV < 0 ))then myAvailV = 0 end  
		   if ((myPercent == nil) or (myPercent < 1)) then myPercent = 0 end  
		   if myPercent > 100 then myPercent = 100 end   

		if (battNorm) then	
			lcd.drawPixmap(xCoord + 1, yCoord + 1, "/SCRIPTS/TELEMETRY/OLIME/battery.bmp")     
				myPxHeight = math.floor(myPercent * 0.37) 
				myPxY = 11 + 37 - myPxHeight				
					if myPercent > 0 then
						lcd.drawFilledRectangle(xCoord + 6, myPxY, xCoord + 21, myPxHeight, FILL_WHITE ) 
					end	
					if (HV_Lipo) then
						lcd.drawText(xCoord+2, yCoord+55,"H ",SMLSIZE)
					end					
		else 
			lcd.drawPixmap(xCoord + 1, yCoord + 1, "/SCRIPTS/TELEMETRY/OLIME/batteryh.bmp") 
				myPxHeight = math.floor(myPercent * 0.20)   
				myPxY = 11 + 13 - myPxHeight				
					if myPercent > 0 then
						lcd.drawFilledRectangle(xCoord + 4, myPxY, xCoord + 9, myPxHeight, FILL_WHITE ) 
					end
					if (HV_Lipo) then
						lcd.drawText(xCoord+24, yCoord+13,"HV",SMLSIZE)
					end
				xCoord = xCoord + 11
				yCoord = yCoord - 7
				offyCoord = offyCoord - 34
		end	   	  
				   if (myCurrent > myMaxV) or (myCurrent < myMinV) then
						lcd.drawNumber(xCoord + 10,offyCoord + 55, myCurrent ,PREC1 + LEFT + BLINK+ SMLSIZE)
				   else
						lcd.drawNumber(xCoord + 8,offyCoord + 55, myCurrent ,PREC1 + LEFT + SMLSIZE)
				   end
				lcd.drawText(lcd.getLastPos(), offyCoord + 55, "V", SMLSIZE)
		   
			if (((HV_Lipo) and (mincell < myMinV/44)) or ((HV_Lipo == false) and (mincell < myMinV/42))) then
					lcd.drawNumber(xCoord + 9,yCoord + 12, mincell ,PREC1 + LEFT + BLINK + SMLSIZE)
			else
					lcd.drawNumber(xCoord + 9,yCoord + 12, mincell ,PREC1 + LEFT + SMLSIZE)
			end
					lcd.drawText(lcd.getLastPos(), yCoord + 12, "V", SMLSIZE)
end
-- RSSI;        SINGLE Row Col Wgt --
local function rssiWgt(xCoord,yCoord,Fullwdgt)

  local rssiNorm = Fullwdgt
  local percent = 0
  local rssiNo = 0
  
  if getVDef("RSSI") > 38 then
		percent = ((math.log(getVDef("RSSI")-28, 10)-1)/(math.log(72, 10)-1))*100
   else
		percent = 0
  end
   
  if percent > 90 then
			rssiNo = 10
	  elseif percent > 80 then
			rssiNo = 9
	  elseif percent > 70 then
			rssiNo = 8
	  elseif percent > 60 then
			rssiNo = 7
	  elseif percent > 50 then
			rssiNo = 6
	  elseif percent > 40 then
			rssiNo = 5
	  elseif percent > 30 then
			rssiNo = 4
	  elseif percent > 20 then
			rssiNo = 3
	  elseif percent > 10 then
			rssiNo = 2
	  elseif percent > 0 then
			rssiNo = 1
	  else
			rssiNo = 0		
  end
		if ((rssiNo > 9) and (rssiNorm)) then
				lcd.drawPixmap(xCoord + 4, yCoord + 1,"/SCRIPTS/TELEMETRY/OLIME/RSSIh"..rssiNo..".bmp")
			elseif ((rssiNo < 10) and (rssiNorm)) then
				lcd.drawPixmap(xCoord + 4, yCoord + 1,"/SCRIPTS/TELEMETRY/OLIME/RSSIh0"..rssiNo..".bmp")
			elseif (rssiNo > 9) then
				lcd.drawPixmap(xCoord + 4, yCoord + 1,"/SCRIPTS/TELEMETRY/OLIME/RSSIh"..rssiNo.."h.bmp")
				xCoord = xCoord + 9
				yCoord = yCoord -38
			else 
				lcd.drawPixmap(xCoord + 4, yCoord + 1,"/SCRIPTS/TELEMETRY/OLIME/RSSIh0"..rssiNo.."h.bmp")
				xCoord = xCoord + 9
				yCoord = yCoord -38
		end
		
	if getVDef("RSSI") < 38 then
     lcd.drawNumber(xCoord + 8, yCoord + 54, getVDef("RSSI"), LEFT + INVERS + BLINK)
     lcd.drawText(lcd.getLastPos(), yCoord + 54, "db", INVERS + BLINK)
   else
      lcd.drawNumber(xCoord + 8, yCoord + 54, getVDef("RSSI"), LEFT)
      lcd.drawText(lcd.getLastPos(), yCoord + 54, "db", 0)
   end
 
end 

-- Current Ampere  MULTI Row Col Wgt --

local function CAmpWgt(xCoord, yCoord)

	local currampere = getVDef("Curr") *10
	
	lcd.drawPixmap(xCoord + 2, yCoord + 2, "/SCRIPTS/TELEMETRY/OLIME/CurrA.bmp")
		lcd.drawNumber(xCoord + 20, yCoord + 7, currampere,PREC1 + MIDSIZE)
	lcd.drawText(lcd.getLastPos(), yCoord+ 9, "A", 0)
	
end
-- Distance;       MULTI Row Col Wgt --
local function distWgt(xCoord, yCoord)

   local dist = getVDef("Dist")
   
   lcd.drawPixmap(xCoord + 2, yCoord + 2, "/SCRIPTS/TELEMETRY/OLIME/dist.bmp")
   lcd.drawNumber(xCoord + 18, yCoord + 7, dist, LEFT)
   lcd.drawText(lcd.getLastPos(), yCoord+ 7, "m", 0)
   
end
--  ALT Height;        MULTI Row Col Wgt --
local function AlthWgt(xCoord, yCoord)
	local flight_height
		lcd.drawPixmap(xCoord + 1, yCoord + 2, "/SCRIPTS/TELEMETRY/OLIME/hgt2.bmp")
		flight_height = getVDef("Alt")
		lcd.drawNumber(xCoord + 18, yCoord + 7, flight_height, LEFT)
		lcd.drawText(lcd.getLastPos(), yCoord + 7, "m", 0)
end

--  GPS Height;        MULTI Row Col Wgt --

local function GPShWgt(xCoord, yCoord)

	local flight_height

	local height = getVDef("GAlt")	
			   flight_height = height - HomeAlt
					if  HomeAlt > 0 then
						lcd.drawPixmap(xCoord + 1, yCoord + 2, "/SCRIPTS/TELEMETRY/OLIME/hgt2.bmp")
					else 
						lcd.drawPixmap(xCoord + 1, yCoord + 2, "/SCRIPTS/TELEMETRY/OLIME/hgtNN.bmp")
					end
					
	lcd.drawNumber(xCoord + 18, yCoord + 7, flight_height, LEFT)
	lcd.drawText(lcd.getLastPos(), yCoord + 7, "m", 0)
end
--  Speed;        MULTI Row Col Wgt --
local function speedWgt(xCoord, yCoord)

   local speed = getVDef("GSpd")  
	lcd.drawPixmap(xCoord + 1, yCoord + 2, "/SCRIPTS/TELEMETRY/OLIME/Vspee.bmp")
	lcd.drawNumber(xCoord + 18, yCoord + 7, speed * 1.852, LEFT)
	lcd.drawText(lcd.getLastPos(), yCoord + 7, "kmh", 0)
end
--  VSpeed;        MULTI Row Col Wgt --
local function VspedWgt(xCoord, yCoord)

   local speed = getVDef("VSpd")
	lcd.drawPixmap(xCoord + 1, yCoord + 2, "/SCRIPTS/TELEMETRY/OLIME/Vspee.bmp")
	lcd.drawNumber(xCoord + 18, yCoord + 7, speed, LEFT)
	lcd.drawText(lcd.getLastPos(), yCoord + 7, "ms", 0)
end
--  RPM ;        MULTI Row Col Wgt --
local function rpmWgt(xCoord, yCoord)

   local speed = getVDef("RPM") 
	   lcd.drawPixmap(xCoord + 1, yCoord + 2, "/SCRIPTS/TELEMETRY/OLIME/rpm.bmp")
	   lcd.drawNumber(xCoord + 18, yCoord + 1, speed , LEFT+MIDSIZE)
	   lcd.drawText(xCoord + 23, yCoord + 13, "RPM", SMLSIZE)
end
--  Heading;       MULTI Row Col Wgt --
local function headWgt(xCoord, yCoord)

   local heading = getVDef("Hdg")  
	   lcd.drawPixmap(xCoord + 1, yCoord + 2, "/SCRIPTS/TELEMETRY/OLIME/compass.bmp")
	   lcd.drawNumber(xCoord + 18, yCoord + 7, heading, LEFT)
	   lcd.drawText(lcd.getLastPos(), yCoord + 7, "dg", 0)
end

-- Timer;          MULTI Row Col Wgt --
local function timerWgt(xCoord, yCoord)

  lcd.drawPixmap(xCoord + 1, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/timer_1.bmp")
  
  local localt = model.getTimer(0)
	if (localt.value < 3600) then
		lcd.drawTimer(xCoord + 16, yCoord + 8, localt.value, 0)
	else
			lcd.drawTimer(xCoord + 16, yCoord + 8, localt.value / 60 , 0)
			lcd.drawText(lcd.getLastPos()+0,50,":",0+BLINK)
	end
 end
 -- GPS;           MULTI Row Col Wgt --
 local function gpsWgt(xCoord,yCoord)
 
		gpsLatLon = getVDef("GPS")
		
		if (type(gpsLatLon) == "table") then
			if ((gpsLatLon["lat"] ~= NIL) and (gpsLatLon["lat"] ~= 0 )) then
				last_pos_lat = gpsLatLon["lat"]
			end
			if ((gpsLatLon["lon"] ~= NIL) and (gpsLatLon["lon"] ~= 0 )) then
				if ((last_pos_lat ~= gpsLatLon["lat"]) or (last_pos_lon ~= gpsLatLon["lon"])) then
					noMove = 0
				else
					noMove = noMove +1
				end
				last_pos_lon = gpsLatLon["lon"]
			end
		end
	
	if ((myNumSat == 0) and (last_pos_lon > 0) and (last_pos_lat > 0)) or ((noMove > 200) and (last_pos_lon > 0))  then     
				lcd.drawText(xCoord +2, yCoord + 3,last_pos_lat , SMLSIZE)
				lcd.drawText(xCoord +2, yCoord + 11,last_pos_lon , SMLSIZE)
	else
			if (myQualSat < 1) then
					lcd.drawPixmap(xCoord + 1, yCoord + 1, "/SCRIPTS/TELEMETRY/OLIME/sat0.bmp")
				elseif (myQualSat < 2) then
					lcd.drawPixmap(xCoord + 1, yCoord + 1, "/SCRIPTS/TELEMETRY/OLIME/sat1.bmp")                
				elseif (myQualSat < 3) then	
					lcd.drawPixmap(xCoord + 1, yCoord + 1, "/SCRIPTS/TELEMETRY/OLIME/sat2.bmp")
				elseif (myQualSat > 2 ) then
					lcd.drawPixmap(xCoord + 1, yCoord + 1, "/SCRIPTS/TELEMETRY/OLIME/sat3.bmp")
			end				
			 
				if myNumSat > 5 then
						lcd.drawPixmap(xCoord + 13, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/gps_6.bmp")
					elseif myNumSat > 4 then
						lcd.drawPixmap(xCoord + 13, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/gps_5.bmp")
					elseif myNumSat > 3 then
						lcd.drawPixmap(xCoord + 13, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/gps_4.bmp")
					elseif myNumSat > 2 then
						lcd.drawPixmap(xCoord + 13, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/gps_3.bmp")
					elseif myNumSat > 1 then
						lcd.drawPixmap(xCoord + 13, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/gps_2.bmp")
					elseif myNumSat > 0 then
						lcd.drawPixmap(xCoord + 13, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/gps_1.bmp")
					else
					lcd.drawPixmap(xCoord + 13, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/gps_0.bmp")
				end
			 
		   lcd.drawNumber(xCoord + 24, yCoord + 1, myNumSat,  SMLSIZE) 
	end
 end
 -- Home Point;    MULTI Row Col Wgt --
local function hpWgt(xCoord, yCoord)
	
	if myQualSat < 1 then								
		  lcd.drawPixmap(xCoord + 1, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/home.bmp")
			if myNumSat < 1 then
				lcd.drawText(xCoord + 19, yCoord + 5, "?", MIDSIZE + BLINK)
			else
				lcd.drawText(xCoord + 19, yCoord + 5,  myQualSat ,  BLINK + MIDSIZE)
			end
		elseif myQualSat < 2 then								
		  lcd.drawPixmap(xCoord + 1, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/home.bmp")
		  lcd.drawText(xCoord + 19, yCoord + 5,  myQualSat ,   MIDSIZE)  
		elseif myQualSat < 3 then								
		  lcd.drawPixmap(xCoord + 1, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/home1.bmp")
		  lcd.drawText(xCoord + 19, yCoord + 5,  myQualSat , MIDSIZE)	  
		elseif myQualSat > 2 then								
		  lcd.drawPixmap(xCoord + 1, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/home1.bmp")
		  lcd.drawPixmap(xCoord + 19, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/check.bmp")
	    else
		  lcd.drawPixmap(xCoord + 1, yCoord + 3, "/SCRIPTS/TELEMETRY/OLIME/home.bmp")
		  lcd.drawText(xCoord + 19, yCoord + 5, myNumSat ,  BLINK + MIDSIZE)
   end
 end
-- Wgt --
local function callWgt(name, xPos, yPos)
	if (xPos ~= nil and yPos ~= nil) then
		if (name == "battery") then
			battWgt(xPos, yPos, true)
		elseif (name == "batteryh") then
			battWgt(xPos, yPos, false)
		elseif (name == "dist") then
			distWgt(xPos, yPos)
		elseif (name == "Altheight") then
			AlthWgt(xPos, yPos)
		elseif (name == "GPSheight") then
			GPShWgt(xPos, yPos)
		elseif (name == "fmAr") then
			fmWgt(xPos, yPos,1)
		elseif (name == "fmINAV") then
			fmWgt(xPos, yPos,2)
		elseif (name == "timer") then
			timerWgt(xPos, yPos)
		elseif (name == "gps") then
			gpsWgt(xPos, yPos)
		elseif (name == "rssi") then
			rssiWgt(xPos, yPos, true)
		elseif (name == "rssih") then
			rssiWgt(xPos, yPos, false)
		elseif (name == "hp") then
			hpWgt(xPos, yPos)
		elseif (name == "speed") then
			speedWgt(xPos, yPos)
		elseif (name == "heading") then
			headWgt(xPos, yPos)
		elseif (name == "dummy") then
			dummyWgt(xPos, yPos)
		elseif (name == "current") then
			totcWgt(xPos, yPos)
		elseif (name == "vspeed") then
			VspedWgt(xPos, yPos)
		elseif (name == "rpm") then
			rpmWgt(xPos, yPos)
		elseif (name == "CAmp") then
			CAmpWgt(xPos, yPos)
		elseif (name == "radar") then
			IFTWgt(xPos, yPos,1)
		elseif (name == "IFT") then
			IFTWgt(xPos, yPos,3)	
		else
			return
		end
	end
end
--   Build Grid    --
local function buildGrid(def)

	local tempSumX = -1
	local tempSumY = -1

	for i=1, # def, 1
	do
		if (# def[i] == 1) then
			xOffset = xOffsetSingle
		else
			xOffset = xOffsetMulti
		end

		lcd.drawLine(tempSumX, -1, tempSumX, displayHeight, SOLID, GREY_DEFAULT)

		for j=1, # def[i], 1
		do
			lcd.drawLine(tempSumX, tempSumY, tempSumX + xOffset, tempSumY, SOLID, GREY_DEFAULT)
			
			callWgt(def[i][j], tempSumX + 1, tempSumY + 1)
			
			tempSumY = tempSumY + math.floor(displayHeight / # def[i])
		end
		
		tempSumY = -1
		tempSumX = tempSumX + xOffset
	end
end

local function background()

	local curr_sat = 0
		curr_sat = getVDef("Tmp2")
		myQualSat = math.floor(curr_sat % 10)
			if ((home_set == false) and (myQualSat > 2)) then
				HomeAlt = getVDef("GAlt")
				set_prearm = true
			end
		myNumSat = math.floor(curr_sat / 10)
	

end
-- ###################### INIT ########################## 
local function init()
	collectgarbage()
	battype = 0			-- dont Support 5s&7s Battery; set to 5 or to 7
	numSingleCols = 0
	numMultiCols = 0
	myQualSat = 0
	HomeAlt = 0
	set_prearm = false 
	prearmheading = 0
	pilotlat = 0
	pilotlon = 0
	sinCorr = 0
	cosCorr = 0
	divtmp = 0
	last_pos_lon = 0
	last_pos_lat = 0
	oldTime={0,0,0,0,0,0}
	Time={0,0,0,0,0,0}
	lastsay=100
	totalbatteryComsum = 0
	compare = 0
	myMaxV = 0
	myMinV = 0
	mincell = 0
	noMove = 0
	home_set = false
	last_fly_mode = 0
	HV_Lipo = false
	F_Roll = 0

	for i=1, # WgtDefinition, 1
	do
		if (# WgtDefinition[i] == 1) then
			numSingleCols = numSingleCols + 1
		else
			numMultiCols = numMultiCols + 1
		end
	end
	xOffsetMulti = (displayWidth - (numSingleCols * xOffsetSingle)) / numMultiCols	
end

-- ####################### Run #########################
local function run(event)

	lcd.clear()		
    background()
	buildGrid(WgtDefinition)
--	lcd.drawText(100,30,(collectgarbage("count")*1024),  BLINK + MIDSIZE)
--	collectgarbage()

end

return{init=init,run=run,background=background}