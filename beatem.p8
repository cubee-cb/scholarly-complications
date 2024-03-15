pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
--beat em up game
--by cubee 🐱

-- use custom font retained from
-- title cart, unless unloaded
--[[--db--]]if(@0x5600==6)--[[--dbe--]]poke(0x5f58,0x81)

-- bEGAN tUESDAY 22 fEB 2022
-- AT 11:30. hAPPY 2SDAY!

--[[

sfx 0-7: instruments

sfx 48-63: split sfx
sfx 40-47: single sfx

]]

--db
printh"=== beatem start ==="
dbver=true

--debug=true

menuitem(5,"toggle debug",function() debug=not debug end)

menuitem(4,"skip",function()
 stg+=1
 initstg(stg,true)
end)

-- i is quite a nice
-- editor theme
poke(0x5f2e,1)
--dbe

#include beatem-init.p8l

#include beatem-data.p8l

#include beatem-levels.p8l

cartdata"cubg-nara"

-->8
--init

function _init()
 -- disable keyrepeat
 poke(0x5f5c,-1)

 loadconstants()

 -- tables
 obj={}
 dust={}

 fx={}

 -- get players from load string
 local lp=stat(6)

 --db
 -- temporary menu
 repeat
  if(btnp(4))lp="nara"
  if(btnp(5))lp="sine"
  if(btnp(1))lp="nara,sine"
  if(btnp(0))lp="sine,nara"
  cls(1)

  ?"scholary complications",20,12,7
  ?"temporary menu",13

  ?"🅾️: nara (1p)",16,60,7
  ?"❎: sine (1p)"
  ?"➡️: nara (1p) + sine (2p)"
  ?"⬅️: sine (1p) + nara (2p)"

  ?"pixel shock 2022",1,122,13
  flip()
 until lp~=""
 --dbe

 --if(lp=="")load("beatem-title")
 lp="nara"

 for k,i in next,split(lp) do
  local a=newact(i,0,24,k-1)
  --a.hp=dget(k)
  add(obj,a)
 end

 players=#obj

 initstg(stg,true)

	fx_list={
 	function(x,y,t,val)

  local sc=sqrt(val)

 	;(t>0.8 and circfill or circ)(x,y,t*6*sc,t>0.8 and 7 or 13)

 	fillp(▒)
 	if(t>0.7)circ(x,y,(1.3-t)*15*sc,split"9,8"[val])
	
 	end,
		function(x,y,t,val)
 	fillp(▒)
		ovalfill(x-t*6,y-3+(t*3)^2,x+t*6,y-t*4,split"13,6"[val%2+1])

		end,
		function(x,y,t,val)
 	fillp(░)
		if(t==1)circfill(x,y,10,9)
 	fillp(▒)
		circ(x,y,(1-t*t)*val,7)
	
		end,
		
		
		
	}

end

-->8
--update

_btnp=btnp

function _update()

local g=_ENV

-- compensate for 30fps
for lp=0,_update and 1 or 0 do
btnp=lp==1 and nullfunc or _btnp

hud_data={}

local playercount=0
local cam_lock=false
cam_xt=0

-- update obj
foreach(obj,
 function(_ENV)
 kleft,kright,kup,kdown,kjump,kpunch=false

 if((stun>0 or hiteffect>0) and not ragdoll)set_anim("stun",stunspr or 0)

 if hitstop>0 then
  hitstop-=1

 else

  -- reload hurtbox
  hurtbox=newhbox(spread(ragdoll and i.kobox or i.hurtbox))

  solid=not i.ghost

  local onfloor=z==0

  -- get target
  if ai and not i.object and (not target or target.hp<=0) then
   target=false
   local valid={}
   for a in all(obj) do
    if not a.ai and #a.engaged<3 then
     add(valid,a)
    end
   end

   target=rnd(valid)

   -- add self to target's queue
   if(target)add(target.engaged,_ENV)
  end

	 -- handle details

	 -- pick a palette variation
	 if i.pal_variants and not pal_variant then
	  pal_variant=hexplit(rnd(split(i.pal_variants)))
	 end

  -- player control
  if not ai then
   kleft,kright,kup,kdown,kjump,kpunch
   =
   btn(0,id),btn(1,id),btn(2,id),btn(3,id),btnp(4,id),btnp(5,id)
  end

  speed=1

  -- ragdoll update
  if ragdoll or hp<=0 then
		 solid=false

		 ragdoll_update(_ENV,0.9)

   set_anim("ragdoll",z==0 and 1 or 0)

		 -- lock ragdolls to locked camera
		 if(cam_lock)x=mid(cam_x+8,x,cam_x+120)

		 if(onfloor)kotimer-=1

		 if kotimer<=0 then
		  if hp<=0 then

		   -- remove self from engage lists
		   for a in all(obj) do
		    del(a.engaged,_ENV)
		   end

		   del(obj,_ENV)

		  -- fighters get up
		  elseif not i.object then
		
		   ragdoll=false
		   stun=15
		   stunspr=set_anim("stun",-1)

		  end
		 end

  -- ai control
  elseif ai then

   running=false

   if target then
			 tx,ty,offset=target.x,target.y,2+(hurtbox.w+target.hurtbox.w)/2

    tx+=x<tx and -offset or offset
		 end

   if not target or not target.ragdoll then
    if(update(_ENV)=="wander")ai_funcs.wander(_ENV)

   end

  end

  local moving=kleft or kright or kup or kdown

	 -- stop moving
  if stun<=0 then

	  if(onfloor)yv=0
	  --xv*=(attack and stopmoving and 0.7 or (attack or not onfloor) and 0.99 or 0.8)
	  xv*=(attack and attacklaunch==1 and 0.7 or (attack or not onfloor) and 0.99 or 0.8)
	  --xv*=attack and attacklaunch=="" and 0.7 or onfloor and 0.8 or 0.99

		 if attacking==0 and not ragdoll then

			 -- move

		  -- running speed
		  local s=speed*(running and 1.6 or 0.8)

			 -- movement
			 if onfloor then
			  -- walk
			  if(kleft)xv=-s dir=true
			  if(kright)xv=s dir=false
			  if(kup)yv=-s/2
			  if(kdown)yv=s/2

			  -- toggle running
			  if not ai then
				  if btnp(0,id) then
				   if dashtimer>0 then
				    running=0
				    make_effect(2,x,y)
				   end
				   dashtimer=15
				  elseif btnp(1,id) then
				   if dashtimer>0 then
				    running=1
				    make_effect(2,x,y)
				   end
				   dashtimer=15
				  end
			  end
			 end

		  -- cancel running
		  if(not ai and (btn(running==0 and 1 or 0,id) or not btn(running,id)))running=false

			 -- animate
			 anim="idle"
			 if moving then
			  anim=running and i["run"] and "run" or "walk"
			 end
			 loop_anim(anim)
	
	
			 --[[ sine's synced bopping
			 pframe=frame
			 if stat(57) and i.musicbop and anim=="idle" then
			  frame=(stat(50)+1)%4
			 end
			 ]]
	
	
			 -- animate jumping
			 if not onfloor then
			  set_anim("jump",zv<-0.5 and 0 or zv<0.5 and 1 or 2)
			 end

			 -- change facing direction
    if target and facetarget then
     dir=x>target.x

			 elseif ai and onfloor then
			  dir=xv<0
			 end

    if i.attacks then
	
			  -- attacks
			  if combo>#i.attacks or combotimer==0 then
			   combo=1
			  end
	
	    -- attacks
	    local sel_attack=false
	    if kpunch then
	
	     if onfloor then
	
	      -- special
	      if running and i.special then
			     sel_attack=i.special
	
	      -- directional
	      elseif kdown and i.altdown then
				    sel_attack=i.altdown
	      elseif kup and i.altup then
				    sel_attack=i.altup

	      -- normal
		     else
			     sel_attack=i.attacks[combo]
			     combo+=1
	
			    end
	
	     else
	
	      -- directional
	      if kdown and i.airdown then
				    sel_attack=i.airdown
	      elseif kup and i.airup then
				    sel_attack=i.airup

	      -- normal
		     else
			     sel_attack=i.air
	
			    end
			    
			    if(sel_attack)air_attack=true
	
	     end

	    end

	    if sel_attack then
	     if(#split(sel_attack,":")==1)sel_attack=i[sel_attack]
	     setattack(spread(sel_attack,":"))
	    end
	
	   end

		 end

   -- add permanent hitbox
   if i.permhitbox then
    --hitbox=newhbox(spread(i.hitbox))
    attacking,attacktime,damage,recovery,attackdelay,combotimer,attackhitbox,attackpower,yv,attacklaunch,ignoreragdoll
    =1,1,spread(i.permhitbox)

   -- set animation and hitbox
   elseif attacking>0 then
    anim=attack
    hitbox=false

    local anim_frame=attacking>attacktime-attackdelay
    local hit_frame=attacking>recovery and not anim_frame

    -- sprite
    local a=i[anim]
    if a and attack then

     if air_attack and onfloor then
      attacking=min(attacking,recovery)
      xv*=.8
      make_effect(2,x,y)
     end

     frame=#a-1
     if #a==1 then
      frame=0

     elseif hit_frame then
      frame=t*(a.speed or 1)\10%(#a-2)+1

      if attacklaunch and type(attacklaunch)=="string" and attacklaunch~="" then
				   attacklaunch=launch(dir and -1 or 1,spread(attacklaunch))
				  end

      -- make hitbox
      hitbox=newhbox(spread(attackhitbox))

     elseif anim_frame then
      frame=0
     end

    end


   else
    gravmod,
    attack,stopmoving,air_attack,ignoreragdoll=
    1
   end

		 -- flip hurtbox
	  if(dir)hurtbox.x=-hurtbox.x-hurtbox.w
	  -- flip hitbox
	  if hitbox and dir then
	   hitbox.x=-hitbox.x-hitbox.w
	  end

		 -- gravity
		 if(not ragdoll)zv+=grav*gravmod

		 -- collisions
		 for a in all(obj) do
		  if a~=_ENV then

		   -- collide hurtbox with hurtbox
		   local ih,ah=hurtbox,a.hurtbox

		   local ix,iy=x+ih.x+xv,y+z+ih.y+yv
		   local ax,ay=a.x+ah.x+a.xv,a.y+a.z+ah.y+a.yv

     -- ycol
		   if abs(y-a.y)<5 then

		    -- walking collisions
		    if not (ix>ax+ah.w or iy>ay+ah.h or
		           ix+ih.w<ax or iy+ih.h<ay) then

	      -- consume consumables
			    if kdown and kpunch and a.i.type=="consumable" and attack then
			     setattack(spread("pickup:20:0:10:8:0,0,-1,-1:1",":"))
			     hp=min(hp+a.hp,max_hp)
			     sfx(41)
			     del(obj,a)

			    elseif a.solid then
	
			     -- horiz
			     if x<a.x and xv>0 or
			        x>a.x and xv<0 then
			      -- gap assist (except if i is the target)
			      -- player gets movement priveleges
			      if a~=target or not ai then
			       y+=sgn(y-a.y)*abs(xv)
			      else
			       xv=0
			      end
			     end
	
			     -- vert
			     if y<a.y and yv>0 or
			        y>a.y and yv<0 then
			      yv=0
			     end
	
			    end
	
	     --boxcol
			   end

	     -- attack collisions
	     if hitbox then
		     local ix,iy=x+hitbox.x,y+z+hitbox.y

       if not a.i.invul and
		        a.iframes==0 and
	         a.i.type~="consumable" and
		        not (ix>ax+ah.w or iy>ay+ah.h or
	              ix+hitbox.w<ax or iy+hitbox.h<ay)
		     then
	 
		      -- damage actor
	       a:takedamage(damage,attacktime,_ENV)
	       xv*=.8
	
	       -- spawn hit effect
	       make_effect(1,ix+(dir and 2 or hitbox.w-2),iy+hitbox.h/2,attackpower~="" and 2 or 1)
	
		     end
	     
	     end

     --ycol
     end

		  end
		 end

   if i.speed and not ragdoll then
		  x+=xv*i.speed
		  y+=yv*i.speed
		  z+=zv
		 end

		 -- lock players to camera
		 if(not ai)x=mid(cam_x+8,x,cam_x+120)

		 -- on ground
		 if z>0 then
		  z=0
		  zv=0
		  jump=false

		  -- jump
		  if kjump and attacking==0 then
		   zv=-i.jumph
		   jump=true
				 make_effect(2,x,y)
		  end

		 end

  end

  -- timers
	 stun=max(stun-1)
	 iframes=max(iframes-1)
	 attacking=max(attacking-1)
	 combotimer=max(combotimer-1)
	 dashtimer=max(dashtimer-1)
	 hiteffect=max(hiteffect-1)
	 if(stun==0)st=max(st+1)

 end

 -- stun sprite
 if stun>0 and not ragdoll and not hitstun then

  -- cancel attacks
  attack=false
  stopmoving=false
  attacking=0
  combo=1
 end

 -- players move to next stg
 if not ai and x+hurtbox.w/2>=#floor*48+48 then
  g.stg+=1
  initstg(stg)
 end

 -- enemies lock the camera
 if ai then
  if not i.object then
   cam_lock=true
  end

 -- camera follows players
 else
  g.cam_xt+=x
  playercount+=1

  -- add hud stats
  add(hud_data,{i=i,hp=hp,mhp=max_hp,id=id})

 end

 -- timer
 t=max(t+1)

 -- cull passed objects
 if (deloffscreen or not cam_lock) and x+hurtbox.w<cam_x then
  del(obj,_ENV)
 end

 y=mid(4,y,48)

end
)-- end update obj

-- go to game over when no
-- players are alive
if #hud_data==0 and mode~="fail" then
 fade()
 mode="fail"
end

-- move camera
if cam_lock then
 got=160
else
 cam_xt=mid(
  64,
  cam_xt/playercount-40,
  #floor*48-80
 )
 local cam_diff=cam_xt-cam_x
	if cam_diff>2 then
	 --cam_x+=2
	 cam_x+=max(cam_diff/10,2)
	else
	 cam_x=max(cam_xt,cam_x)
	end
end


-- go flashing
got=max(got-1)
if(not cam_lock and (got/40)%1==0.8 and got>0)ssfx(59)

-- spawn new obj
for k,pos in pairs(actor_groups) do

 if pos and cam_x>=pos-64 then
  got=0

	 for id,a in pairs(stgs[stg][k]) do

   local row=split(a,"|")
   local offsets,i,level,spawntype,data=split(row[2]),spread(row[1])

   for o in all(offsets) do
    local offset=split(o,":")

    local _ENV=newact(i,offset[1]+pos+64,offset[2],-1,level,data)

    -- trigger spawners
    if spawntype=="spawner" then
     z,zv,yv=-12,-2,1

	    sfx(40)

	    -- splode the bg
	    if(bg[x\64])bg[x\64]+=1

	    splode(127,x,y,16,20,20)

    end

    add(obj,_ENV)

   end
   
  end

  actor_groups[k]=false

 end

end--actor spawning

-- update dust
for _ENV in all(dust) do
	ragdoll_update(_ENV,0.97)

 -- bounce off of walls
 if y<0 then
  yv=abs(yv)*0.8
  y=0
 elseif y>48 then
  yv=-abs(yv)*0.8
  y=48
 end

 l-=1
 if l<=0 then
  del(dust,_ENV)
 end

end

gt=max(gt+1)

end--framerate compensation
end

-->8
--draw

function _draw()
camera()
cls(14)

pal()
palt(0,false)
palt(14,true)

-- copy world gfx
memcpy(0,0xa000,0x2000)

palt(14,false)
palt(15,true)

local function map_piece(id,x,y,w,h,f)
 local id,w,h=id or -1,w or 8,h or 9
 local tw=128/w
 if(id>0 or w==6)map(id%tw*w,id\tw*h+(w==6 and 18 or 0),x,y,w,h,f)
end

-- rear bg
dpal"1"
for i=0,3 do
 map_piece(bg2[cam_x*0.85\64+i],i*64-16-cam_x*0.85%64,8)
end

pal()
palt(0,false)
palt(15,true)

-- front bg
for i=0,2 do
 map_piece(bg[cam_x\64+i],i*64-cam_x%64,8)
end

-- 3d bg tiles
for o=0,3 do
 dpal(min(3-o,1))
 for i=0,2 do
  map_piece(bg[cam_x\64+i],i*64-o-cam_x%64,o+8,8,9,1)
 end
end

-- floor
for i=0,3 do
 map_piece(floor[cam_x\48+i],i*48-cam_x%48,56,6,9)
end

-- sort obj
local sortedobj=sorty(obj)

poke(0x5f54,0x60)
dpal"2"

-- draw particle shadows
for x in all(dust) do
	draw_shadow(x,8)
end

-- draw actor shadows
foreach(sortedobj,draw_shadow)

camera(cam_x,-80)
poke(0x5f54,0)

pal()
palt(0,false)
palt(14,true)

-- draw dust
for _ENV in all(dust) do
	spr(id,x-4,y-8+z)
end

-- copy actor gfx
memcpy(0,0x8000,0x2000)

-- draw obj
foreach(sortedobj,draw_actor)

-- fx
for _ENV in all(fx) do
 if(t>=5)func(x,y,t/10,val)
 fillp()

 t=max(t-1)
 
 if(t<0)del(fx,_ENV)
end

camera()

-- hud
rectfill(0,0,127,11,0)
for i in all(hud_data) do
 local xo,d,name=i.id*128,1-i.id*2,split(i.i.name)[1]

 multispr(i.i.icon,xo+8*d,7,d==-1)
 print(name,xo+16*d-(i.id==1 and #name*4 or 0),0,7)
 print(i.hp.."/"..i.mhp,xo+16*d-(i.id==1 and #tostr(i.mhp)*8+4 or 0),6)

end

-- go sign
if got>0 and (got/40)%1<0.8 then
 for ix=-1,1 do
  for iy=-1,1 do
   print("\^w\^tgo!",ix+104,iy+40,4)
  end
 end
 rect(103,50,124,52,4)
 print("\^w\^tgo!",104,40,9)
 line(104,51,123,51,9)
end

-- fade overlay
unfade()

pal(gamepal,1)

-- sky bg gradient
poke(0x5f5f,0x3e)
for i=0,15 do
local s=skypal[sky]
pal(i,s[i+1] or s[#s],2)
end
memset(0x5f70,0xaa,16)

--db
?#obj,1,16,7
--dbe

end

-->8
--actor functions

function newact(i_,x_,y_,id_,level_,data_)

 local _ENV=setmetatable({},{__index=_ENV})

 i=objects[i_] or objects["nara"]

 level=level_ or 1
 levelmod=1+(level-1)/3

 --common
 t=rnd(100)\1
 st=0
 hp=i.health*levelmod
 max_hp=hp
 x,y,z=x_,y_,0
 xv,yv,zv=0,0,0
 aitype=i.ai or ""
 update=ai_funcs[aitype] or nullfunc
 data=data_
 hurtbox=newhbox(spread(i.hurtbox))
 hitbox=false
 --scale=1
 dir=false
 anim="idle"
 frame=1
 running=false
 hitstop=0

 --fighters
 id=id_ or -1
 ai=id<0
 engaged={}
 kotimer=0
 hiteffect=0
 dashtimer=0
 combo=0
 combotimer=0
 stun=0
 attacking=0
 wandertime=0
 wandertarget={x=x,y=y}
 ignoreragdoll=false
 state_id=1
 iframes=0

 function setattack(anim,time,dmg,delay,recover,hitbox_,attacklaunch_,power,ignoreragdoll_)
  attack,attacking,attacktime,damage,recovery,attackdelay,combotimer,attackhitbox,attackpower,yv,attacklaunch,ignoreragdoll
  =anim,time,time,dmg*levelmod,recover,delay,time+20,hitbox_,power or "",0,attacklaunch_,ignoreragdoll_

  -- uninterruptible attack ping
  if ai and ignoreragdoll then
   ssfx(56,4)
   make_effect(3,x,y-hurtbox.h/2,hurtbox.h*0.75)
   hiteffect=10
  end
 end

 function takedamage(_ENV,dmg_,stun_,attacker)
  if not ignoreragdoll then
	  stun=max(stun_-(ai and 0 or 15))
	  iframes=stun_
	  attacking=0
	  attack=false
	  hitbox=false
  end

  if dmg_>0 then
   kotimer=(hp>0 and 90 or 180)*(i.kotime or 1)
   hp=max(hp-dmg_)
   if(attacker and not i.object)x+=dmg_*sgn(x-attacker.x)
   if(i["stun"])stunspr=rnd(#i["stun"]-1 or 3)\1
   hiteffect=10
   if(i.hurtsound)ssfx(63,i.hurtsound,8)

   hitstop=3+dmg_
   if(hp<=0 and not ai)hitstop*=5
   if(attacker)attacker.hitstop=hitstop

	  -- spawn consumables
	  local dropchance=(i.dropchance or 1)
	  if not ragdoll and (dropchance<=1 and i.drops and rnd()<=dropchance) then
	   local dropped=newact(rnd(split(i.drops)),x,y)
	   dropped.pal_variant=pal_variant
	   do
	    local _ENV=dropped
	    z=-12
	    ragdoll=true
	    launch(1,-1+rnd"2",1.5,-1+rnd"2")
	   end
	   add(obj,dropped)
	  end

  end

  local d=attacker.dir and -1 or 1

  -- turn into a ragdoll when ko'ed, combo'ed, or in the air
  if ragdoll or not ignoreragdoll and (hp<=0 or (not i.embedded and (attacker.attackpower~="" or z~=0))) then
   ssfx(57,rnd(4))
   ragdoll=true
   if attacker.attackpower~="" then
    local xl,zl,yl=spread(attacker.attackpower)

    -- launch more if in air
    if(not z==0)xl*=2 yl*=2
    launch(d,xl,zl,(yl or 0)*sgn(y-attacker.y))
   else
    launch(d,1,2,sgn(y-attacker.y))

   end

  else
   ssfx(56,rnd(4))

  end

  if not attacker.ai and not i.object then
   -- change target
   if target then
    del(target.engaged,_ENV)
   end

   target=attacker

   add(attacker.engaged,_ENV)
  end

 end

	function loop_anim(anim_)
	 local a=i[anim_]
	 if(not a)return
	 anim=anim_
	 frame=t*(a.speed or 1)\10%#a
	end

	function set_anim(anim_,frame_)
		if(not i[anim_])frame=0return
		anim=anim_
	 frame=frame_%#i[anim_]
	 return frame
	end

	function launch(sign,xd,zd,yd,grav)
	 xv,yv,zv,gravmod=
	 (tonum(xd) and xd*sign) or xv,tonum(yd) or yv,-(tonum(zd) or -zv),grav or 1
	end

 ----------

 return _ENV

end



function draw_actor(_ENV)
if hp>0 or kotimer>60 or t%8>1 then
 local xo=0

 -- flash/shake on hit
 if hiteffect>3 then
  xo=sin((hiteffect+hitstop)/8)*hiteffect/3
  pal(hexplit"5566d67776656775")

 -- use variant palette
 elseif pal_variant then
  pal(pal_variant)
 end

 -- default to idle
 if not i[anim] then
  anim="idle"
 end

 local frame=i[anim][frame+1]

 -- does frame exist?
 if frame and frame~="*" then
  -- handle redirects
  if not tonum(frame[1]) then
   frame=split(frame,":")
   frame=(frame[3] and objects[frame[3] ] or i)[frame[1] ][frame[2] ]
  end

  -- draw frame
  multispr(frame,x+xo,y+z-1,dir, 1)--]]scale)
 end

end

pal()
palt(0,false)
palt(14,true)

--db
if debug then

 line(x,y,tx,ty,3)
 circ(tx,ty,3,8)

 local hx,hy=x+hurtbox.x,y+z+hurtbox.y
 rect(hx,hy,hx+hurtbox.w-1,hy+hurtbox.h-1,7)
 -- visualise hitbox
 if hitbox then
  local hx,hy=x+hitbox.x,y+z+hitbox.y
  rect(hx,hy,hx+hitbox.w-1,hy+hitbox.h-1,8)
 end

 ?hp.." "..iframes.."\n"..#engaged,x-8,y+z-hurtbox.h-12,7
end
--dbe
end


function draw_shadow(_ENV,w)
 local shadlines=split"4,7,9,10,9,7,4"

 for k,xo in pairs(shadlines) do
  xo*=(w or hurtbox.w)/16
  xo+=z/10
  local tx,ty=x-xo-flr(cam_x),y+k+75
  sspr(tx,ty,xo*2,1,tx,ty)
 end

end

-->8
--ai functions

ai_funcs={

wander=function(_ENV)

 local range=4

 if abs(wandertarget.x-x)<range or
    abs(wandertarget.x-x)<range then

  wandertime-=1
  if wandertime<=0 then
   wandertarget={x=cam_x+rnd"128",y=rnd"48"}
   wandertime=60+rnd"240"
  end

 end

 kleft=x>wandertarget.x+range
 kright=x<wandertarget.x-range

 kup=y>wandertarget.y+range
 kdown=y<wandertarget.y-range

end,

fighter=function(_ENV)
 if(not target)return "wander"

 local range=2

 kleft=x>tx+range or x>target.x and not dir
 kright=x<tx-range or x<target.x and dir

 if y>ty+1 then
  kup=true
 elseif y<ty-1 then
  kdown=true
 end

 -- attack
 if t%10==0 and
    abs(x-tx)<range and
    abs(y-ty)<6 then
  kpunch=true
 end

end,
--db
flying=function(_ENV)
 if(not target)return "wander"

 if x>target.x then
  kleft=true
 else
  kright=true
 end

 if y>target.y then
  kup=true
 else
  kdown=true
 end

end,
--dbe
dog=function(_ENV)
 if(not target)return "wander"

 facetarget=true
 local state=t%220>140
 local offset=0
 local d=sgn(target.x-x)

 if state then
  offset=0
  running=true
  side=sgn(rnd"-1")
 else
  offset=40*(side or 1)
  speed=.75
 end

 local range=2

 kleft=x>tx+offset+range or x>target.x and not dir
 kright=x<tx+offset-range or x<target.x and dir

 if y>ty+1 then
  kup=true
 elseif y<ty-1 then
  kdown=true
 end

 -- attack
 if t%10==0 and
    abs(x-tx)<range and
    abs(y-ty)<6 then
  kpunch=true
 end

end,

boss=function(_ENV)
 if(not target)return "wander"

 -- get current state
 local move,states=true,split(i.states)
 local state,duration=spread(states[state_id],":")

 facetarget=true

 -- run state

 -- pace right
 if state==1 then
  tx=cam_x+112
  ty=24+sgn(sin(t/220))*20

 -- pace left
 elseif state==2 then
  tx=cam_x+16
  ty=24+sgn(cos(t/220))*20

 -- align right
 elseif state==3 then
  tx=cam_x+112
  ty=target.y

 -- align left
 elseif state==4 then
  tx=cam_x+16
  ty=target.y

 -- charge
 elseif state==5 then
  move=false
  punch=true
  anim="charge"
  state=6
  xv,yv=0,0

 -- dash
 elseif state==6 then
  move=false
  punch=false
  kpunch=punch
  running=true

 -- use fighter ai
 elseif state==-1 then
  ai_funcs.fighter(_ENV)

 -- 
 elseif state==1 then


 end

 -- move to target
 if move then
  local dx,dy=tx-x,ty-y
  kleft=dx<0
  kright=dx>0
  kup=dy<0
  kdown=dy>0
 end

 -- loop states
 if st>duration then
  st=0
  state_id=loop(state_id+1,#states)
 end

end,

vehicle=function(_ENV)
deloffscreen,kleft=true,true
end,

ragdoll=function(_ENV)
 ragdoll=true
end,



}
-->8
--other functions

function nullfunc()
end

function ragdoll_update(_ENV,v)
 xv*=v or 0.95
 yv*=v or 0.95
 zv+=grav

 x+=xv
 y+=yv
 z+=zv

 if z>=0 then
  z=0
  if zv>.8 then
   zv=-abs(zv*0.5)
   ssfx(58,rnd(8),2)
	 	make_effect(2,x,y)
  else
   zv=0
  end
  xv*=0.7
  yv*=0.7

  iframes=0
 end
end

function make_effect(id_,x_,y_,val_)
	local _ENV=setmetatable({},{__index=_ENV})
 func=fx_list[id_]
 x=x_
 y=y_
 t=10
 val=val_ or rnd"-1"\1

 add(fx,_ENV)

end

--[[

you're telepathetic

you project your lack of skill
onto others

]]
__gfx__
ffffff0ffffff0df90cb4b99403ce637efffffffffffb20c5cfffb780effffb081fffff9084cfffff042b58fffff18e6d883efffe7283c0fffff5015b62ffffe
d337183a274e1f701e73bf79ff9a44be0bb8b04c1836129b62f01d79ff3ec59fb98c641f43c19e5d6e8f0675397e97e8952d78cff2374e79c5fc4e0984d3c3f5
44844f112bd569beb5c3fc30e9f95f7ce17e9edc571f4c122d384d697e9fe97cbfe2278340b1c5fc775972afb3f76eb3e53267e12e0c84a14a6f87ead5dbfeb3
2cb9c225406cefece864838344e8ae3ed6be0968e1b72942293e8be8349c31fc19304a9405418efd231bc33cc2d32bf4adb298e19fe39e59c174f8afc3bea570
e9e7fe2fda74aef0d50eeff1848c4ec19a483852706fc5dd37ca46e27ce1f0ea4eb784f93e8671bc5f809034a6c13d3ef716261598de974cc052e069d1c380f0
193f8ebadb8444418002ff794c6995c99854eae3795d724254464a023f30f5b24019490cff7298e1753f42cca75b8c66f419d1b86e7e4270ff3c7a63302f4067
12ba0d0b5e8554e8dff09fff4a375edd695299c3ebe57d6244e997c0bc3effff4eaf2f622fe675464ea09c65e844219c4279ffb1f77f9211a69c5e8b3596adf0
49fa6cc2e8fff1fb72b3c12a94e8f879f1cf06f30fff278d19842f9b4ebcbe29b2be15baf4e842fe9f4ea552c30b5ec8cf1f68ff75eb17c1c3c2f119af88d7f4
6be5711be07b4ecba74979467ccc1fbcf0c54a376ef75d8fcf1935271c2f42dd522162f07d7998097dafe1e62f7cd7909c59a0e1f5801e0fd1078443c310294a
9e776e8b77484298fed431e70d7838383251a9661f107858c652786240086259c3f9c974a152893eaf76a4a226ab524a0360acf0ca4c25224def9b385043110a
c579f7e07579444afd1fb487216a6c148de783df521ebe1075ecdf19f1e86b437c17446b2198b4567c44c51e362fb0b832240bcf1e85278c76c11e32907cd774
a3068c1740112c1025c59cd9fe579c866d2bc85814e0f3c322fcf3b0c202ea66896f0597ef929bc5eb3c8369c16f41f883abbfdbdee7f5c596396d61d27d5162
3e84d5dad648696a972e9327e639f1ea6218b27d3fdbf3c53796eb6815c8f7610bcc565eedebc5bf3afd02174e1ebcf2671fedd297ec7e387eab22f38579fe8d
3fc974722ffc298c1212461fdf4bfe9c5b76f5c2221787f198df29e527c17d1d9843d3639f92cf117fa7dbe9a577e5db4c5df74bc57887cff6e8a8a56f9dd28f
9c55b17ce8fec8b393a2bc3983f983c9398e19a8ffd47d4d5dc6a50ef9cf2f448e8072c54e3ea0aa81a58fff40d4a1d840fb5cea0d05e76effcb56d3463f79df
cea0fb9cff8d838e231b3cedc552f9b378f562427cbe3efffc8cf596ebc69c197456cee532e8bfdf6143f87c0ffaf5e8cf19f4a94e2f856b3c6c1c37c178f219
a9ac934c302e98ef0fb84a0542efcd1f83679c119722f471e882059873aeb384c59a83e405690a2ffcbd1d721fbac51b72c333dbe9e5beb9179019329bf85eab
5e27463f48b807a9a3c378097af93cd93d32f03a1e4af4ce9319f838a9ebb7e45e01178ccda7c3752d58017856abd5fc79a01e0b3a6797217087c395e14e19b8
a98f8d97c67e5ff039f36f117ac77c3b7de940a992547f3c993827ea98d2e72952b4778e56eae9e8f5cf1cdbcf2780b9cd75ea7e9db7c02fc583854ceb978194
b469f5e3e82ff844ad56b83bae875fc33adace2978d4fa6eab258d48c580a675e2407c7ecf2f38b5eaf385a991324a944e9807c67eae9af70d7cab3c17c3bcf3
e16d62b30c0bc5d368d4c1c5936e27ceb45a421e0765f019c772cf002e9e2e1d7e7051169758466b332139c371ba3838b222a4462dd1294357d3ce52e4ebf745
4e89a335b54f8c2f85f83e8f1abfeefe9468f30cf5b4f6b3af7099347e02fc4432025f5eb7f9f7eaf7c36970bda5c1f858c3bfef83f038f3ef74c5d5e02bfc7e
e88724e830f5fb3bf8fea6e78dc3c7f4adf5e1be133159fcff0bf34ce15e0c53e5679479ceff16f9dff88f2b8d299429429d23673f372fe22fb8d72f36edf344
e70d3e836eba589d2b44421278cf1eb1bd1bd1a4e9d575628b442f08d162942f6299f96e89c42dc32f4612f7de78f5e994c62f07ce9f104e9f2c5bd3117e1906
0911edcf3aab503c1db01acf47c579f100212c29d3e8227c29f74543f7c17783b7112fee2a462e479140dbdcf4b252426b9b45731251fc1237f7112e07c3744e
07c17a7e6dc3b46b420d120782c2fd94eccf197b2e8f126dc69c964ea5d7e3dd29d4fcf49c31c215f4d9e1125e3029624a7f3bda3c84211129d62e808acc156b
ef1fb09729c80f3142029f5c832019f29452429803e0fd469cd369094e9c2f488308b69444efb0a50daf258095e090830bfe79c42c420ba574e397219cea8d71
9f133b19088097082f78466837f78763bf564246b429d6129a2b0563f9f127bfbc8409f344f80942d02b78fe8c1f706df2b5821ec09d26a4e2231f5223176858
178dfa3fde1597996ce9f1e9ff2627c35f8ce8b0b5c730ee108ff94c562a7e2f5b93cce78def35a7885e6700fc631dca22101091ef7422bd3426dce9f1199fb2
6cc2139bae70488cff94294e39ec19f1373b3852eaedc90392ae445eb448ffbc1998ff35a48f3278121712cf048ffd02cfd1d54e159e16f55d213b5221424e94
6b5ef0bff31f34af53274d1943271146e1b1b4c57c194a622cf09c122fffae19eae029c166bd29f68f8f789d433bccb5f277a6f5fff4e331b0834ef0750c1cd9
9a11b052c18385c8379b27a01eb9d378480805078d390042e3e2ad10401ba6328f2f3c942bd1e27c29c274e01c8ce0bd3362f70f0f48f4642316678b019c4d1b
e70dcc32b4c4f9a5894599366fc69bd3b2213983e024852819848f4e707c28c24e699d3bf88112675cc02e0b4d3624426b098d0c12f8efbe512069a323bd1a9c
36512d22cdbf3ce09622c5c5b0fb9be9c2f98e5d91836b034d6b19a1b9a904699c19123c2420e3e78eea7e88d599c27c1bd714a11b369422133b0621c435e02c
d34903e70ed3ecf32b544290d3ce96c1b466d52d57e80402c162a23efe0701df108e2bc531207cc0426a312d489e6afa476c1d4694cff52951a11368775e4313
4a231112261532bb0f7c61326d144fff4e8cc769bcc221a1b4ceb521bc319ce04220b43986531e1cbe780ff79c313202950170487cee8a10ce9860c4e8361c14
8ffdd3203e90905e71980e704ce532fffccf0ef10757cf3fb5eef3e71f30fdb43df8f078df361f55e5f0e2012c91bff92bde80f3c5cf3917c2c80ea400081454
2004ef7b42d302489cc500e8b67c127853524c39c39d20e94c61effca29cf222375096e1e39ffff4d52946e2952d493c257b1a1e1074872cff8391391c1e3aff
0fa4832c1e11a3c30ef7b1eca9eff1d1fff75ca62cfff58deb4cf28ff19df34d9f7ce8b2ffaf5834d16ffc5f83a91962cffac93ef6e7e85c567dcce21e9cea36
ffb47451f764fcc227ee51e0b309583ec329406cffbce4ef7064cc35b3a12ce8787d1e5e00636cff94e6e74a1f4ddf529ab4fefe96c295ecdf094221fcffa8b5
ef262bc3e09bc57c39f3e14c6919327ce96eff82f8372fbf67c15d7c39d5756b9b39ca64e700fff2da2efe4ea5e9cf15cc3797ea3e05742c9f319c19ff15469f
1002fb40ff5254c54e2843b6223b9ef3696e9b0eff22def2521ffcfae342df38eb51c3faf6f01df134cef742bd1ffcd8fd7f579e3fd39b221579386a1a2f3d1d
cafeff8ce192ff662d7237a54caae830b2f7579cdff3a478938f50f33b52b33cc99c1701b5cf984dff942a88f70f8bb9f276981e600e8d5d368f47aef4effd27
8ac27acfa7c193009f3b3cff93951594e08c227bd35fa0f38dbd078cf27c2f7cae1c29bef74aff444a7e1609461a24e5b3e7ac3753bdedf129f3ec78ef239d17
0dc5cff5b787ff8e47169380132fbc67cf261c61a2f348b3bc3c27eb4c79f3eebe8caff762893a0990c978cf1767f5ff19cc59f1cef01e704ecccddbce03539f
f9ac46022880efbc9f1cef8c31fbceacdfd3f34f6f3cb74df1ecf3e8761e90ffbde63f8cf3cf1e01c29752678cf2fbcce4f83ad7fb9b3bf1cb8f1e9cff571932
25614ef11f0bb8e3cd94d640df342eaf588388469c9c16aeffa3a1f30fac2da0aad5422324c19546e0bfc19d311d84263c2c4ef7ba9cac36d6d319ef2f425b8c
34100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffff0ffffff0df5c9bb42ce8041f75834e9caf4e8df19d1f3b7e9c6ff5aef29f12942db87a67ca7936d7cf07863fdf8bbe97e94f9fd41f70983e6be1bd1c86
b3b6670e66bc57df6bf2e3efa98f364e10742e9580b624b9073b342fdefad1c598f962ef8a4d3c19837109662de2cdc0227d1f7de1e3bf76b8f3e095cd31f91f
50dc4ad58b9117a83efad7c7cf231f7c32b4cb0e9c8c17ce0994bb38176eb3ae41fcf639be942f7c21f7496a0e94c5152d646744e79c67569fbe80fc1f0f3c21
f7444692f4833b38d224ae098627e63ebce094ff2537c578be39d61f7c3292f2097f214193237caa78352b0f645e8ef585ae719ca3f740bdcb319ce5e5663e0e
0b0d7ea48cf012e9ff0cf2898f328c230f42a10a12f66145244ef04adfbc2cf358f3285291f48302e01e908842b0a22190f702b3ef2b0ffc65f7462bc27ec2fc
32224667440590b0f7029cff92fc7f7d63f27d3229c3452454854e712affdcaff0f3916c10ea36617b9c1e8daa39cf09094ef266782e08cf36237787a9329627
c1012003002cf39becf137fdf4fa3af34df0f426862b342337443488c3f8094bd63a784e797000e3cf11e27c55740987f29873dcf09454290bc1232394a09148
e69b0743150008537cf21eacc5d7fcfa8b52f48f122209002124200fad068bef1300ccf5c59b2f9f8b52e306984311c6104e7a452020d83ea6124285316ff85c
1f31839c44328321e3a311f188811000a639b28d840b2f78311b1fb86839c0d62945028ba2d4010901060a8f160b265927ae719f98f3622b02111100d9858580
0c41483eb8042267c0f9779c6cff5e9448d22006cf2b003628083600cce707c1de22cf09c517cff7a070800b36454454011740743c8322e13c593e122cf261ef
f3529a8421a61019626a2f3c340404e11d41b64e84990f31ffb09d398444021690d1e9c3693470381ecba86ce83a22cf146bd3fb0839d219622853842ef93c3f
8872021dbc10318c39bf12ff832e9ff8b78661c1b06e0a61d32974c1929d708d59c82e8e08f7cef72f4e43ad42922734ab34f846dc1d0900807167cc19f12c12
3ff4c5fff07e6d79eb3191fc256294219124e8131ac833d3e02fd1367c3fcf193cff3220bf16ce806e5f4070b8d5ab4a683238c0970bac38d346d0841fdffd67
c14fc5e94fdb74e685eec5227fdc727d527ff02f3097e2ba3c1e8e4c02111844402119ffd1b76c17c1c48fdc7e9f36f5ea8f29c7d8bc19bc1595c19d314444ea
39393dd718443ff3bd84c44f7557c7faa0fcf193269d1915fc04274c67ac02edc2cffc22f4cef54ed746588f12f989029cc078380602e511cffee899809c1708
c31ea899cd123edcf19a3a38c8f7624a40802f0221ff73cf0a96accbb70b42759e38d2746f81aed32d3c1c6e7227c95aa42418cffde9c20958278d26227debd1
56a317858467445d6842700210840021eff6c31bf3c176e95638e8621929d117d2ba70699cff9790f81d472c09d317c9197fbed65f4885cf0fdbf43b9365ff7f
0952f8b2f9c23e3c13134f8f16868362e78d1ba7888fff303080ef893e8a9c9f83298c31f8888c3bf69323fff708ab8e1c998b08879e7f0b383e94f9889afff7
01315b4f0dd670c3122646c188ced842d0f842996c36179fffb0d627923e96a36094902d06275296c3af8f42229119c4e0fff722e03e079401d125ca1c211788
8b2ba3ea90a80b6aefff44c109f66832af4d33521c123597e6a43111dfffb39bf784e8b461102ba0e2b3201626c39c378d17462942fff7b246142dce10c60270
908babe1bd2d2bfffb5c56c2cd3ce7a21942d4229ffff7cbd579c2262c3cc3c510efff7d3b880c1440b329720204b39c4929cfff1bb7995a21e84222b4246e3e
8c356fc11a7ffff5b70a74b05932042f44e3efffd2741293279befffe1102e78b6936c4c0e1427e1e0ebceeb3fff705fa85684084c7bcf0c2d3efff75a7d1c70
944411bc27e128fff369d9fbee6228f0112fff703fef07c56511557cf111294bfff7b4eace87e5784452ce78d608ffff701422ac21fc8b3ad46fff7f4071f070
767966e78fff75edf737e7f35eeeffffffffffffffff09f000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000222222220000101010101010101010101010101010101010101010101010101010101010101010101010101010104f4f4f4f4f4f4f4f4f4f4f4f4f6d4f4f4f4f4f4f4f4f6e4f2c2d2d2c2c2c2c2c2c2c2c3d2c2c3c2c2c2c2c2c2c2c2c2c2e2e4f4f4f4f4f4f2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2121000000000000
0022000000002200101010101010101010101010101010101010101010101010101010101010101010101010101010104f6f00006e5d4f4f4f6e5d6f6e6d006e4f4f4f4f4f6f006e2c2c2c2d2d2c3d2d2c2c3c3c3c3c2c3c2d2d2d3c3c2c2c3c2e2e4f4f6f4f4f4f2d2d2d3c3c2c2c3c2d2d2d3c3c2c2c3c2121000000000000
2200000000220022101010181908101010101018190810101010101010101010101010181908101010101018190810106f000000006d006e6f006d00006d0000005d6e6f00005e4f2c2c2c2d3c2d3c3c3c3c3c3c2c2d2c3c2d2d2d2c3c3c2d3d2e2e4f6f006e4f4f2d2d2d2c3c3c2d2c2d2d2d2c3c3c2d2c2121000000000000
2200000022000022101010050607101010101030303010101010101010101010101010101010101010101010101010105f0000004e6d000000006d00006d0000006d4e0000004f4f2c3d2d3c2c3c3c2c2d2c2d3c2c3c3c3c2c2c2c2d3c2c2d3c2e2e4f5f00006e5d2c2c2c0506072d3c2c2c2c3030302d3c21212a2a2a2a2a2a
2200002200000022131410151617101013141012111210101010131413141010131413141314131410101010101010104f5f005e4f6d5e4f4f5f6d4e5e6d5f005e6d4f5f005e4f4f2c2c3c3c2c2d3c3c2c3c2d2c2c2c3d3c2d3c2c3c3c2c2d2c2e2e4f4f5f4e006d2d3c2c1516172c2c2d3c2c1112112c2c21212a2a2a2a2a2a
2200220000000022232410151617101023241012111210101010232423241010232423242324232410101010101010104f4f4f4f4f6d4f4f4f4f6d4f4f6d4f4f4f6d4f4f4f4f4f4f2c2c2c2c2d2d3c2d2d2c3c2c2c2d2d2d2d2c2d2d3d2c2d2c2e2e4f4f4f4f4f6d2d2c2d1516172d2c2d2c2d1112112d2c21213a3a2a3a2a3a
0022000000002200233210252627101023321012111210101010233223321010233223322332233210101010101010103f3f3f3f3f7d3f3f3f3f7d3f3f6d3f4d3f6d3f3f4d3f3f3f2c3c2c3c2d3c3c3c2c3c3c3c2c2c2c3c3c3c3c2d2c2c2c2c2e3e3f3f4d3f3f6d3c3c3c2526272c2c3c3c3c1112112c2c2131010201020102
0000222222220000333420353637202033342012111220202020333433342020333433343334333420202020202020203f4d3f3f3f3f3f3f3f4d3f3f3f7d3f3f3f7d3f3f3f3f3f3f2c2c3c3c3c2c2c3d2c2c2c3c3c3c2c2c3c2d2d2c3c3c2d2c3e3f3f3f3f3f3f6d3c2d2d3536372d2c3c2d2d1112112d2c2202010201020102
0000000000000000010201020102010201020102010201020102010201020102010201020102010201020102010201023f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f4d7d3f1f040303042f4d3f1f040303042f4d0102010201020102
00000000000000004c4b4c4c4c4b4c4c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007575525252757575000000000010101021212100000000000000000000000000
00000000000000006a5b5c6a6a5b5c6a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007575626262757575000000000010101021212100000000000000000000000000
00000000000000006b6b6c6b6b6b6c6b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000757575757575757500000000001010102121212a2a2a2b000000292a2a000000
2a2a2a2a2a2a2a2a7a7a6c7a7a7a6c7a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000727272727272727500000000001010102121213a3a3a3b000000393a3a000000
2a2a2a2a2a2a2a2a7b7b6c7b7b7b6c7b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007272727272727275000000000010101021213101022f4d3f3f3f1f0102000000
3a2a3a3a3a2a2a3a2c494a2c2c494a2c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000727272727272727500000000001010102122022f3f3f3f4d1f01020102000000
01020102010201022c595a2c2c595a2c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060636460636463600000000000101010312f4d3f3f3f1f010201020102000000
0102010201020102040303030403030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006073746074737460000000000000000000000000000000000000000000000000
01020102010201023d2c2c2c3d2c2c2c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060606060606060600000000f00000000000f00000000000f0000000000000000
0000000000000000000000002a2a2a2a2a2a2a2b0000292a2a2b000000000000000000290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000002a2a2a2a2a2a2a2b0000292a2a2b000000000000000000290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003a3a3a3a3a3a3a3b0000393a3a3b0000000000000000003909090a0b090909090a0b0909090909090a0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007070707070707070707070700000
010201020102010201020102090a0b090909090a0b090909090c0d1d1d1d1d1d1d0e0f09090a0b090909090c0d1d1d1d1d1d1d0e0f090a0b09090a0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007171717171717171717171710000
0102010201020102010201021b1a1b1b1b1b1b1a1b1b1b1b1b1c1d1d1d1d1d1d1d1e1b1b1b1a1b1b1b1b1b1c1d1d1d1d1d1d1d1e1b1b1a1b1b1b1a1b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006060606060607070707070700000
010201020102010201020102030304030403030304030403030304030403030304030403404040404040404040404040404040404040402c3c2c40400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006060606060607272727272720000
0102010201021010101010100403030304030403030304030403030304030403030304034040404040404040404040404040404040402d3c40402d400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006060606060606565656565650000
010201020102101010101010040304030303040304030303040304030303040304030303404040404040404040404040404040404040402d2d2d402d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006060606060607272727272720000
0102010201022020202020200303040304030303040304030303040304030303040304034041424243404041424243404041424243403c3c404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006060606060606565656565650000
00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f00000000007f0000
__sfx__
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040000266402564023640206401f6301c6301a630186301662013620106200c61008610086101163500000106350000000000106350c625000000e625000000e6250c61500000000001061500000000000c615
0f08000011053166501f65520650100531a05523055280552a0552b0502b0502b0302b01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d080000187431062300000000001a0331061300000000001773310623006000000019033116150000000000323623233232315241002f3002f3002f300231003230032300323002610035300353003530029100
900c00001415310103001030010318153101030010300103161530010300103001031715311103001030010327103001030010300103001030010300103001030010300103001030010300103001030010300103
1908000014615080051661508005186150800519615080050f6150800511615080051361508005086150800508005080050800508005080050800508005080050800508005080050800508005080050800508005
8d0400001f7401f7301f7200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001500300000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404000013054250621f051150521404314023000010000103164161510e1510b1520a14308133081130110128754357622e741257212270121701000000000113000250001f00015000110000b0000000000000
