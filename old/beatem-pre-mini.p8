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
 stage+=1
 init_stage(stage,true)
end)

-- this is quite a nice
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
 actors={}
 particles={}

 effects={}

 -- get players from load string
 local loadplayers=stat(6)

 --db
 -- temporary menu
 repeat
  if(btnp(4))loadplayers="nara"
  if(btnp(5))loadplayers="sine"
  if(btnp(1))loadplayers="nara,sine"
  if(btnp(0))loadplayers="sine,nara"
  cls(1)

  ?"scholary complications",20,12,7
  ?"temporary menu",13

  ?"🅾️: nara (1p)",16,60,7
  ?"❎: sine (1p)"
  ?"➡️: nara (1p) + sine (2p)"
  ?"⬅️: sine (1p) + nara (2p)"

  ?"pixel shock 2022",1,122,13
  flip()
 until loadplayers~=""
 --dbe

 --if(loadplayers=="")load("beatem-title")
 loadplayers="nara"

 for k,i in next,split(loadplayers) do
  local a=create_actor(i,0,24,k-1)
  --a.hp=dget(k)
  add(actors,a)
 end

 players=#actors

 init_stage(stage,true)

	effects_list={
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

-- update actors
foreach(actors,
 function(_ENV)
 kleft,kright,kup,kdown,kjump,kpunch=false

 if(ragdoll)set_anim("ragdoll",z==0 and 1 or 0)


 if hitstop>0 then
  hitstop-=1
 else

  -- reload hurtbox
  hurtbox=make_hitbox(spread(ragdoll and this.ragdoll_hurtbox or this.hurtbox))

  solid=not this.ghost

  local grounded=z==0

  -- get target
  if ai and not this.object and (not target or target.hp<=0) then
   target=false
   local valid_targs={}
   for a in all(actors) do
    if not a.ai and #a.engaged<3 then
     add(valid_targs,a)
    end
   end

   target=rnd(valid_targs)

   -- add self to target's queue
   if(target)add(target.engaged,_ENV)
  end

	 -- handle details

	 -- pick a palette variation
	 if this.pal_variants and not pal_variant then
	  pal_variant=hexplit(rnd(split(this.pal_variants)))
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

		 -- lock ragdolls to locked camera
		 if(cam_lock)x=mid(cam_x+8,x,cam_x+120)

		 if(grounded)kotimer-=1

		 if kotimer<=0 then
		  if hp<=0 then

		   -- remove self from engage lists
		   for a in all(actors) do
		    del(a.engaged,_ENV)
		   end

		   del(actors,_ENV)

		  -- fighters get up
		  elseif not this.object then
		
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

	  if(grounded)yv=0
	  --xv*=(attack and stopmoving and 0.7 or (attack or not grounded) and 0.99 or 0.8)
	  xv*=(attack and attacklaunch==1 and 0.7 or (attack or not grounded) and 0.99 or 0.8)
	  --xv*=attack and attacklaunch=="" and 0.7 or grounded and 0.8 or 0.99

		 if attacking==0 and not ragdoll then

			 -- move

		  -- running speed
		  local s=speed*(running and 1.6 or 0.8)

			 -- movement
			 if grounded then
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
			  anim=running and this["run"] and "run" or "walk"
			 end
			 loop_anim(anim)
	
	
			 --[[ sine's synced bopping
			 pframe=frame
			 if stat(57) and this.musicbop and anim=="idle" then
			  frame=(stat(50)+1)%4
			 end
			 ]]
	
	
			 -- animate jumping
			 if not grounded then
			  set_anim("jump",zv<-0.5 and 0 or zv<0.5 and 1 or 2)
			 end

			 -- change facing direction
    if target and facetarget then
     dir=x>target.x

			 elseif ai and grounded then
			  dir=xv<0
			 end

    if this.attacks then
	
			  -- attacks
			  if combo>#this.attacks or combotimer==0 then
			   combo=1
			  end
	
	    -- attacks
	    local sel_attack=false
	    if kpunch then
	
	     if grounded then
	
	      -- special
	      if running and this.special then
			     sel_attack=this.special
	
	      -- directional
	      elseif kdown and this.altdown then
				    sel_attack=this.altdown
	      elseif kup and this.altup then
				    sel_attack=this.altup

	      -- normal
		     else
			     sel_attack=this.attacks[combo]
			     combo+=1
	
			    end
	
	     else
	
	      -- directional
	      if kdown and this.airdown then
				    sel_attack=this.airdown
	      elseif kup and this.airup then
				    sel_attack=this.airup

	      -- normal
		     else
			     sel_attack=this.air
	
			    end
			    
			    if(sel_attack)air_attack=true
	
	     end

	    end

	    if sel_attack then
	     if(#split(sel_attack,":")==1)sel_attack=this[sel_attack]
	     setattack(spread(sel_attack,":"))
	    end
	
	   end

		 end

   -- set animation and hitbox
   if attacking>0 then
    anim=attack
    hitbox=false

    local anim_frame=attacking>attacktime-attackdelay
    local hit_frame=attacking>recovery and not anim_frame

    -- sprite
    local a=this[anim]
    if a and attack then

     if air_attack and grounded then
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
      hitbox=make_hitbox(spread(attackhitbox))

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
		 for a in all(actors) do
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
			    if kdown and kpunch and a.this.type=="consumable" and attack then
			     setattack(spread("pickup:20:0:10:8:0,0,-1,-1:1",":"))
			     hp=min(hp+a.hp,max_hp)
			     sfx(41)
			     del(actors,a)

			    elseif a.solid then
	
			     -- horiz
			     if x<a.x and xv>0 or
			        x>a.x and xv<0 then
			      -- gap assist (except if this is the target)
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

       if not a.this.invul and
		        a.iframes==0 and
	         a.this.type~="consumable" and
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

   if this.speed and not ragdoll then
		  x+=xv*this.speed
		  y+=yv*this.speed
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
		   zv=-this.jumph
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
  set_anim("stun",stunspr or 0)

  -- cancel attacks
  attack=false
  stopmoving=false
  attacking=0
  combo=1
 end

 -- players move to next stage
 if not ai and x+hurtbox.w/2>=#floor*48+48 then
  g.stage+=1
  init_stage(stage)
 end

 -- enemies lock the camera
 if ai then
  if not this.object then
   cam_lock=true
  end

 -- camera follows players
 else
  g.cam_xt+=x
  playercount+=1

  -- add hud stats
  add(hud_data,{this=this,hp=hp,mhp=max_hp,id=id})

 end

 -- timer
 t=max(t+1)

 -- cull passed objects
 if not cam_lock and x+hurtbox.w<cam_x then
  del(actors,_ENV)
 end

 y=mid(4,y,48)

end
)-- end update actors

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

-- spawn new actors
for k,pos in pairs(actor_groups) do

 if pos and cam_x>=pos-64 then
  got=0

	 for id,a in pairs(stages[stage][k]) do

   local row=split(a,"|")
   local offsets,this,level,spawntype,data=split(row[2]),spread(row[1])

   for o in all(offsets) do
    local offset=split(o,":")

    local _ENV=create_actor(this,offset[1]+pos+64,offset[2],-1,level,data)

    -- trigger spawners
    if spawntype=="spawner" then
     z,zv,yv=-12,-2,1

	    sfx(40)

	    -- splode the bg
	    if(bg[x\64])bg[x\64]+=1

	    splode(127,x,y,16,20,20)

    end

    add(actors,_ENV)

   end
   
  end

  actor_groups[k]=false

 end

end--actor spawning

-- update particles
for _ENV in all(particles) do
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
  del(particles,_ENV)
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

-- sort actors
local sortedactors=sorty(actors)

poke(0x5f54,0x60)
dpal"2"

-- draw particle shadows
for x in all(particles) do
	draw_shadow(x,8)
end

-- draw actor shadows
foreach(sortedactors,draw_shadow)

camera(cam_x,-80)
poke(0x5f54,0)

pal()
palt(0,false)
palt(14,true)

-- draw particles
for _ENV in all(particles) do
	spr(id,x-4,y-8+z)
end

-- copy actor gfx
memcpy(0,0x8000,0x2000)

-- draw actors
foreach(sortedactors,draw_actor)

-- effects
for _ENV in all(effects) do
 if(t>=5)func(x,y,t/10,val)
 fillp()

 t=max(t-1)
 
 if(t<0)del(effects,_ENV)
end

camera()

-- hud
rectfill(0,0,127,11,0)
for i in all(hud_data) do
 local xo,d,name=i.id*128,1-i.id*2,split(i.this.name)[1]

 multispr(i.this.icon,xo+8*d,7,d==-1)
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
?#actors,1,16,7
--dbe

end

-->8
--actor functions

function create_actor(this_,x_,y_,id_,level_,data_)

 local _ENV=setmetatable({},{__index=_ENV})

 this=objects[this_] or objects["nara"]

 level=level_ or 1
 levelmod=1+(level-1)/3

 --common
 t=rnd(100)\1
 st=0
 hp=this.health*levelmod
 max_hp=hp
 x,y,z=x_,y_,0
 xv,yv,zv=0,0,0
 aitype=this.ai or ""
 update=ai_funcs[aitype] or nullfunc
 data=data_
 hurtbox=make_hitbox(spread(this.hurtbox))
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
   kotimer=(hp>0 and 90 or 180)*(this.kotime or 1)
   hp=max(hp-dmg_)
   if(attacker and not this.object)x+=dmg_*sgn(x-attacker.x)
   if(this["stun"])stunspr=rnd(#this["stun"]-1 or 3)\1
   hiteffect=10
   if(this.hurtsound)ssfx(63,this.hurtsound,8)

   hitstop=3+dmg_
   if(hp<=0 and not ai)hitstop*=10
   if(attacker)attacker.hitstop=hitstop

	  -- spawn consumables
	  if hp>0 and rnd()<.7 and this.drops then
	   local dropped=create_actor(rnd(split(this.drops)),x,y)
	   do
	    local _ENV=dropped
	    z=-12
	    ragdoll=true
	    launch(-1+rnd"2",2,-1+rnd"2")
	   end
	   add(actors,dropped)
	  end

  end

  local d=attacker.dir and -1 or 1

  -- turn into a ragdoll when ko'ed, combo'ed, or in the air
  if ragdoll or not ignoreragdoll and (hp<=0 or (not this.embedded and (attacker.attackpower~="" or z~=0))) then
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

  if not attacker.ai and not this.object then
   -- change target
   if target then
    del(target.engaged,_ENV)
   end

   target=attacker

   add(attacker.engaged,_ENV)
  end

 end

	function loop_anim(anim_)
	 local a=this[anim_]
	 if(not a)return
	 anim=anim_
	 frame=t*(a.speed or 1)\10%#a
	end

	function set_anim(anim_,frame_)
		if(not this[anim_])frame=0return
		anim=anim_
	 frame=frame_%#this[anim_]
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
 if not this[anim] then
  anim="idle"
 end

 local frame=this[anim][frame+1]

 -- does frame exist?
 if frame and frame~="*" then
  -- handle redirects
  if not tonum(frame[1]) then
   frame=split(frame,":")
   frame=(frame[3] and objects[frame[3] ] or this)[frame[1] ][frame[2] ]
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
 local move,states=true,split(this.states)
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
 end
end

function make_effect(id_,x_,y_,val_)
	local _ENV=setmetatable({},{__index=_ENV})
 func=effects_list[id_]
 x=x_
 y=y_
 t=10
 val=val_ or rnd"-1"\1

 add(effects,_ENV)

end

--[[

you're telepathetic

you project your lack of skill
onto others

]]
__gfx__
ffffff0ffffff0df90cb4b9940de2637efffffffffffb20c5cfffb780effffb081fffff9084cfffff042b58fffff18e6d883efffe7283c0fffff5015b62ffffe
d337183a274e1f701e73bfff7321da3ce2e20170e8584ea9c344ffff911bd82e9686a75793e38d5d4e97e8ec29e14efffe844ae1e9f22242af809de29c5f52ad
28efffd97a48d2b7eb7e17e9b84c128d0ea7e9b243afff78242584d6e9b675fd7fd80f62b84118dfff3ad594239c1bbe8929722f4a02d4282a0fff79e8afc3ba
ec187afc9bc7be23f78e207ffff12374a92a9c1f09e3d3431bc3780903466c10bfff741e9c170ec367e5de5422130208dffff9c0424602cf0c7da04229218fff
745467c28f939cfff1c5ab729cfffbf98162efff9722129946efff97d8117efff57f38df07ce1bff989d2194e359b2fa34e8c67d59345a98fe2d342c30b5ee8c
f1f68ff7561e838785644ae2267c59dea7e7026d1e69c775f782f29cea9a3e79f18b847eccffaac7ef8c929b069729e1fd31903938bebc448cb6d7f6739f3eeb
484ea450f8f248078fe08342a1e900942d4f8f27cdb724294edfed431e70d7838383251a9661f107858c652786240086259c3f9cd74a152893faf76a4a226ab5
24a0360acf0ca4c25224def9b385043110ac979f7e6f479444afd9fb487216a6c148de783df521ebe1075ecdf19f1e86b437c17446b21b8b4567c4443c7c4e71
617448069f3c1b4e09fc832c7421e8bfe8470c093e802248304a8b29b3febe291dca5691b038c1ef8744e9f7618504c5dc03de1a2fcf35279bc77817c293ce92
e11747f3cd7bddfe38b2d62dad2a5eab2c46c19aba5bd80d2d43f4c374ecd62f3c5d42075ea7eb7f78b6e2dc7d03a81ffc20699bcacdbd79b6f74fb142e8c3c7
9f5ce2edbb52fc9fc70fc5754e70be2fd1b7e93f8e44ef9521934248c2ebf96fd39b6fceb85442e0fe321bf52db4e83ea3a3196a7c62f358f32ee5fa7d35beeb
ba798baff869be01f8ffdc1515bce3bf140f39ba63e8d1fc51f62745697217e3178b721d3251ffb9ea9aba9d4b0cf39f5e980d11e48b8c7c5145134b0fff90a9
43a190e7b8d51a1acfccff97bca78c6ef2bf9d51e739ff1b170d562678db9fa4e376e0fbc484e87d7cfff919fb2dc79d2932f8ac8ddb64c17fbfd286e1f81ef5
fbc19f32f9439c5e1bc678d8387e83e0f5225359b688704c31df1e71941a84cf9b3e17ce29322f44e9e2c1150a21f64d77098b2517c90ac2145ef97b3af42e75
9b26f48766a7d3db6d733e21227427f1bc57bc5e8c6e90711e435787e012f4f378b37a74e1643c94f98d3722f17053d77fc9ac122e099b5f87ea4ab012e0bc47
bbe9f2512c1674de2f42e00f872bc38c3271531f1b3f8decbef162f7ce32e49fe8767ad3904335a8ee7833705ec531b5cf42b469ee0dbcc5d3d1fb8f38b79f5e
01639bfac5fc3b7f814e9b070b88d73f032969c2fbc7c15ef1984bbc61765d1fae7764b59d72f0b9e5dc575a0b909b014deac580e8fcbf5e707bc5f70b433364
84398c311e8dec5d35ff0af857783e8769f7c3cad46708169ba7c0b9838b27cc5e8d79a4942c1ecae1229fe48f104c3d5c3afcf0a22c2fa09cc676426297e265
70707544498c4ab34296aea78db4c9c7ff8a8c13576a6b8e195e1be17c1f347fddfd39c0f708fb69ed674ff02378ec14e9986404aebc7fe3ffc5ff87c2f06b5b
83e1b0976fdf17e160f7cff88babc14679fcd11f48c170ebe776f1fd5dcf0b978fe94bfbc36d3662a2f9ff16f788d3a417d879d52d52bff78d76ff32ebc26b46
2942946bc8ddcfc9cbb8cf26f9cf897ff019f14f83e89fa6166bc211948c12f78f6c67c67829767d5990e219c306789429cb946e7a93623943f8c3958cf5bf1e
797621b9c3c1b7e70097eb07d6f44c974281464873ff8ae61c074f2482f3d17d5e7008480b46f83a8c1b4ef151dcf1db3c9db809777152317abc028ed6e7a592
121bdc5aab909a87e099bfb801783e9322783e83d3fa6e952b5218e01834169fe4276ef8cb517cf01b66b4e4327dae3f9e69c6a7e7a4e90698a7ae4f8092f109
4312dbf9d6d164298809c631740456e82b5ff8f58c394648f902109cf26c1188c794a2129448178f62b4ee1b4842f469724c10c5b4222ff50d286d79248c2784
0c18d7fb462162185da32f9c3984675ceb8cf899d840448c3049f34233c9bf3c3b9df23212b529c6b09459582b9fcf09bdf56428cf12a748429609d3c774e8f3
0be79d2490768c6135271998f2199833c2c83ce7d9f6f8acbc436fcf0fcf71393e9a7467c58d2eb107f00cff42e231d379fadc166f3c6ff92d34c27b30876b98
665190808c0ff3219de121b66fcf88ccf51366989c55f30244eff42942f947e8cf89b9d1c2175f6e48941572a2f522cff5e8c4cff9252cf193c098b01e702cff
601efe8e22f8a4f0bfaa6989d2190212f42bd2f78dff98f12dfa193ae84a19b8023f8d852ea3e8425311e784e019ff75f84757094e03bd69c73c7cf3cc6a9956
eda79b35bfaff72f99850c12f78b20e0eec4d885821e0c1c26c9bc593580fdce93424048283ce940021f171de0028855b11c79f1e429de079369469327806467
8de9139f387872c72329903b3c58846ae85f3866e19526af4d2c4aacc13b76bcde9519894c17012c21c8442c72f3836146127bcce9d74c801bb26601785ae131
221b584c60e0974ff5fa010b4d199de0d4e1ba09611eedf16784311e2ea58fdc5f469f44faec0c1b581a6bd84d8d4d402bc4e8c09161210f1f3477d374ceac46
93e8deb02d88d1b4219899503906a92701ee1a481f30fe17ef19d222948e16f43e8523be29ea3740201e031591f778388ef004795ea90183660213d90962c473
d75a33e862b42eff29ca0d8813cbb27a981259988011b8a19d58f16b811be02aff72746e3bc566190d8526fd2985e98467021185a944ba90f0e5f348ffb4e981
109c288302c36774d006f4430627c1b0e02cffee1181f48482fb8440f3026fa19ff76e70ff08ba3ef9fd27ff1fb8f18fe5a9e7c783cef1b8fa2fa7071801ec8d
ff49d6748f1e2ef9c8361640752000c0a221002ffb529e1012c46e2007c5b3e093ca9212e94e9c610f426b0ff76594e71199b2843f0f9cfff7ae2942379c296a
c169abd0d0f0832c31ef7c9c89c0e0f1df78752c11e0f80d1e10ffbd076d4fff8e8fffb26531efff2c6f52e71cff8cef1aef8f367c59f7df2c1ae0bf7ea7c1dc
8431ef75ec1f73f37c2e2bb666790f467d1bff5a3aa8f33a7661937fa078d18c2c17e194203eff5672ff30326e9ad1d0167c3cbe0f2700b13eff4273f32d87ae
ef294d5a7f7f4369c27ee78421987ef75cd2f71395e178c5ea3e9cf1f026bc8c1936f43ff7497c939fd7b3e8ae3e9ceab2bdcd946532f308ff79651f7727d2f4
ef826e9bc37d178a321ecf984e8cff822bcf0009f528ff2922e22714a953199d4ff1b43fc50ff7196f79298f7e75f129ef14fda0e97d7b788ef8126ff329de8f
7e6cfebfab4f9fe9c5198abc143d059f9e866d7ff746f849f7339e3993d226557c1859fbab4eeff15a3cc1cf28f99d29d916ec4e8388d2ef44aeff42154cf387
cddc793b4c073007ceae13c7a35f72fff693456935e7d3e8c108cf9d1effc9ca8a42704619bde9a758f1ced6834e79369f365f069c5ff32df7222d3f03842b05
12fad1f35e9ba9d6fef09cf17e34f799ce8386e2effad3cbf747ab0bc148819f56b3e71b06b059f12cd95e1693f52ebcf17f5746dff331cc158c40ec34ef83bb
faff846eacf06f780f302766eee56789a9cff45623011440ff5ecf06f74e98f5675eefe9f1a7bf1ed3ae717ef17c3b0f48ffd67b974ef1ef078069cb21b34e79
f5667a7c1debfdcd9df0e5cf0f4effab8c1192b02ff8878d54f1ee4a6328ef1217df24c1442b4e4e035ff7d1d8f1875696505de2219112e8c22378d7e8ce9886
421b16162ffb5d465e1b6be984f79729a54e1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
