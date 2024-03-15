pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
--editor

--[[

i wasn't joking when i said i
threw this together

behold!

]]

#include beatem-init.p8l
#include beatem-data.p8l
#include beatem-levels.p8l

game_init=_init
game_update=_update
game_draw=_draw

char=split("0123456789abcdef",1)
function edit_init()

 reload(0,0,0x4300,"beatem.p8")
 loadconstants()
 reload(0,0,0x4300,"beatem.p8")

 t=0

--[[
 gamepal=split"133,2,137,4,5,6,7,8,9,3,142,130,134,140,143"
	skypal=split("129,129,1,1,140,140,12|132,132,4,4,137,137,134|0,0,129,129,129,129,1|129,129,129,129,131","|")
 for k,i in pairs(skypal) do
  skypal[k]=split(i)
 end
 dark=split"12,12,4,2,1,13,6,12,3,5,4,0,5,10,11"
 light=split"5,4,9,3,13,7,7,11,15,13,15,2,6,14,7"
 light[0]=12
]]
 mode=1
 floor={0,0,0,0}
 bg={1,2}
 bg2={}
 cam_x2=0
 sky=4
 area=0
 name,desc=false,false
 seltile={floor=1,front_bg=1,rear_bg=1}
 seltileid={floor=0,front_bg=0,rear_bg=0}

--

	groupmode=true
	actormode=false

 groupsel=0
 groups={}
 sn=16
 
 actor_type=split"fighter,smashable,spawner"
 sel_type=1
 
 popt=0
 poptext=""
 
 actors={}
 for k,i in pairs(objects) do
  add(actors,k)
 end
 sel_actor=1

 cam_x2=64

 -- enable devkit mode
 poke(0x5f2d,1)

--

 modes=split"floor,front_bg,rear_bg"

 menuitem(2,"set name",function()
 
  name,desc=false
  n,d="",""

  repeat
   cls()
   
   while stat(30) do
    k=stat(31)
    if k=="\r" then
     poke(0x5f30,1)
     name=n
    elseif k=="\b" then
     n=sub(n,1,#n-1)
    else
     n..=k
    end
   end

   ?"enter name: \n"..n

   flip()
   
  until name

  repeat
   cls()
   
   while stat(30) do
    k=stat(31)
    if k=="\r" then
     poke(0x5f30,1)
     desc=d
    elseif k=="\b" then
     d=sub(d,1,#d-1)
    else
     d..=k
    end
   end

   ?"enter description: \n"..d

   flip()
   
  until desc

 end)

 menuitem(1,"export layout",function()
  save_data()
  repeat
   cls()
   ?name or "untitled stage",9
   ?"copied layout to @clip",7
   ?"press 🅾️/z to continue"
   --?str
   flip()
  until btn(4)

 end)

 menuitem(3,"load stage",function()
 
  local stage=false
  local lsel=1
  repeat

   -- yes, this actually exists.
   -- it's needed here for btnp
   -- to work
   _update_buttons()

   if(btnp(0))lsel-=8
   if(btnp(1))lsel+=8
   if(btnp(2))lsel-=1
   if(btnp(3))lsel+=1
  
   lsel=(lsel-1)%#stgs+1

   cls()
   local num=0
   title="missing name"
   for k,i in pairs(stgs) do
    if i.t then
     title=split(i.t)[1]
     num=1
    else
     num+=1
    end


    --title
    print("stage" ..(num>1 and " "..num or ""),1,48+(k-lsel)*7,k==lsel and 9 or 6)
   end
  
   flip()
  
   if(btnp(4))stage=stgs[lsel]
  
  until stage

  -- load stage
  init_stage(lsel,true)

  local ti=stage.t or ""
  name,desc=split(ti)[1],split(ti)[2]

  -- load actors
  groups={}
  for k,g in pairs(stage) do
   if tonum(k) then
	   add(groups,{actors={},x=actor_groups[k]})
	
	   --g=split(g,";")
	   --gp=deli(g,1)
	   for ik,i in pairs(g) do
	
	    act=split(split(i,"|")[1])
	    pos=split(split(i,"|")[2])
	
	    for p in all(pos) do
	
	     p=split(p,":")
	
	     add(groups[k].actors,{type=act[1],
	     group=k,
	     x=p[1],
	     y=p[2],
	     spawner=act[3],
	     stage=act[2]})
	
	    end
	
	   end
	   
   end
  end

 end)

end

function edit_update()
 str=""

 -- autosave
 if t%(60*30)==0 then
  save_data()
 end

 tmode=modes[mode]

	if tmode=="floor" then
	 current=floor
	elseif tmode=="front_bg" then
	 current=bg
	elseif tmode=="rear_bg" then
	 current=bg2
	end

 s=64
 local function cam()
		if(seltile[tmode]<1)seltile[tmode]=1
	 if tmode=="floor" then
	  cam_x2=seltile[tmode]*48-40
	 elseif tmode=="rear_bg" then
	  cam_x2=(seltile[tmode]*64-48)*(1/0.85)
	 else
	  cam_x2=seltile[tmode]*64-32
	 end
	 
 end
	if(btnp(0))seltile[tmode]-=1 cam()
	if(btnp(1))seltile[tmode]+=1 cam()
	--if(btn(0))cam_x2-=4
	--if(btn(1))cam_x2+=4


 local id=seltile[tmode]
	if(btnp(2))seltileid[tmode]+=1
	if(btnp(3))seltileid[tmode]-=1

 -- place tiles
	if btnp(4) then
	 if id>#current then
	  repeat
	 	 add(current,seltileid[tmode] or 0)
	  until #current==id
	 else
 	 add(current,seltileid[tmode] or 0,id)
	 end
	end

 -- remove tiles
	if(btnp(5))deli(current,id)

 cam_x2+=stat(36)*s

 while stat(30) do
  k=stat(31)
  if(k=="\t")actormode=not actormode
  if(k==",")sel_actor-=1
  if(k==".")sel_actor+=1
  if(k=="q")spawnermode=not spawnermode

  -- GO hOME
  if(k=="h")groupsel=1 seltile[tmode]=1 cam()

  -- jUMP TO END
  if(k=="j")groupsel=#groups seltile[tmode]=#current cam()



  -- cycle modes
  if(k==" ")mode+=1
  if(mode>#modes)mode=1
  --[[ mAP
  if k=="m" then
   area+=1
   area%=#areas+1
		 if area==0 then
    reload(0,0,0x4300,"beatem.p8")
		 else
		  tospr(areas[area],64,0,0)
		 end
  end]]

  -- group jump
  local gj=false
  if k=="[" then
   groupsel-=1
   gj=true
  end
  if k=="]" then
   groupsel+=1
   gj=true
  end
  groupsel=loop(groupsel,#groups)
  if gj and #groups>=1 then
   cam_x2=groups[groupsel].x-63
   popup("group "..groupsel.." | "..#groups[groupsel].actors.." actors")
  end

  -- SnAP
  if(k=="n")sn=sn==4 and 16 or 4

  -- sKY
  if(k=="s")sky=loop(sky+1,#skypal)

  -- hex nums to add
  local hex=tonum("0x"..k)
  if type(hex)=="number" then
   if btn(5) then
    if(current[camid-1])current[camid-1]=hex
   else
    add(current,hex)
   end
  end
  -- bkspc to delete
  if(k=="\b")deli(current,#current)


 end
 
 --if(btnp(5))tilemode=not tilemode
 
 pmd=md
 md=stat(34)==1
 pmr=mr
 mr=stat(34)==2

 mx=(cam_x2+stat(32)-64+4)\sn*sn
 my=(stat(33)-80+4)\8*8

 --if(btnp(5))groupmode=not groupmode

	--if groupmode then
	
	 sel_actor=loop(sel_actor,#actors)
	 sel_type=loop(sel_type,#actor_type)

  if actormode and (#groups==0 or groupsel==0) then
   actormode=false
  end

  -- right click
  if mr and not pmr then

   -- delete actors
   if actormode then

    delact=false
    g=groups[groupsel]
    for k,act in pairs(g.actors) do

     if dist(mx-g.x-act.x,my-act.y)<6 then
      delact=act
     end
    end
    
    if(delact)del(g.actors,delact)

   -- delete groups
   else
    delgroup=false
    for k,group in pairs(groups) do

     if dist(mx-group.x,my-24)<6 then
      delgroup=group
     end
    end

    if(delgroup)del(groups,delgroup)
   end

  -- left mouse
  elseif md and not pmd then

   -- place actors
   if actormode then
    add(groups[groupsel].actors,{type=actors[sel_actor],group=groupsel,x=mx-groups[groupsel].x,y=my,spawner=spawnermode,stage=1})

   -- add/select groups
   else

    -- select near group
    addnew=true
    for k,group in pairs(groups) do
     if dist(mx-group.x,0)<10 then
      addnew=false
      groupsel=k
      mousecarry=true
      carry_mx=mx
      carry_my=my
     end
    end

    -- add new group otherwise
    if addnew then
     add(groups,{actors={},x=mx})
     groupsel=#groups
    end

   end
  end

  -- keep selected in range
  if groupsel>#groups then
   groupsel=#groups
  end

  -- actor type
  subtype=actors[sel_actor]

 -- stage mode
	--else
	
	--[[
	 while stat(30) do
	  local k=stat(31)
	  if(k=="\t")sky=loop(sky+1,#skypal)
	
	  -- hex nums to add
	  local hex=tonum("0x"..k)
	  if(type(hex)=="number")add(current,hex)
	  -- bkspc to delete
	  if(k=="\b")deli(current,#current)
	 end
	]]
	 mode=loop(mode,#modes)

 --end

 --cam_x2=max(64,cam_x2)

 if mousecarry then
  if md then
   if dist(mx-carry_mx,my-carry_my)>2 then
    groups[groupsel].x=mx
   end
  else
   mousecarry=false
  end
 end

 t=max(t+1)
 popt=max(popt-1)

end

function edit_draw()

 pal()
 cls(14)

 local tmode=(modes[mode] or "unknown")

 palt(0,false)
 palt(15,true)

 color(7)

 -- rear bg
 dpal(1)
 camera(cam_x2*0.85%64,-8)
 for i=0,3 do
  if(current==bg2)camid=(cam_x2*0.85)\64+i
  local id=bg2[(cam_x2*0.85)\64+i] or "empty"
  if(id~="empty")map(id%16*8,id\16*9,i*64-16,-8,8,9)
  if(tmode=="rear_bg")rect(i*64-16,-8,i*64+48,72,seltile[tmode]==(cam_x2*0.85)\64+i and 8 or 7)?id,i*64-14,2
 end

 pal()
 palt(0,false)
 palt(15,true)

 -- front bg
 if tmode~="rear_bg" then
	 camera((cam_x2)%64,-8)
	 for i=0,2 do
   if(current==bg)camid=cam_x2\64+i
   local id=bg[cam_x2\64+i] or "empty"
	  if(id~="empty")map((id%16)*8,id\16*9,i*64,0,8,9)
	  if(tmode=="front_bg")rect(i*64,0,i*64+64,72,seltile[tmode]==cam_x2\64+i and 8 or 7)?id or "empty",i*64+2,2
	 end
 end

 -- 3d bg tiles
 if tmode~="rear_bg" then
	 camera((cam_x2)%64,-8)
 	for o=0,3 do
	  dpal(min(3-o,1))
 	 for i=0,2 do
 	  local id=bg[cam_x2\64+i] or 0
	   if(id~="empty")map((id%16)*8,id\16*9,i*64-o,o,8,9,1)
	  end
	 end
 end

 -- floor
 camera(cam_x2%48,-24)
 for i=0,3 do
  if(current==floor)camid=cam_x2\48+i
  local id=floor[cam_x2\48+i] or "empty"
  if(id~="empty")map((id%21)*6,18+id\21*9,i*48,32,6,9)
  if(tmode=="floor")rect(i*48,56,i*48+48,56+48,seltile[tmode]==cam_x2\48+i and 8 or 7)?id,i*48+2,58
 end

 palt(15,false)
 palt(14,true)


 camera(cam_x2-64,-80)

 -- copy actor gfx
 memcpy(0,0x8000,0x2000)

 -- draw groups
 for k,group in pairs(groups) do
  
  -- screen area
  if k==groupsel or not actormode then
   fillp(actormode and (t%20<10 and 24495.5 or -20640.5) or 0b0111111111011111.1)
   rectfill(group.x,-127,group.x-127,127,actormode and 2 or 5)
   fillp()
   rect(group.x,-127,group.x-127,127,actormode and 8 or 13)
   if(k==groupsel) then
    bprint("screen zone",group.x-84,-32)
   end
  end
  circ(group.x,24,3,k==groupsel and not actormode and 9 or 4)

  -- draw actors
  for a in all(group.actors) do

   dpal"1"
   fillp(▒|0b.11)
   if k==groupsel then
    fillp()
    dpal(actormode and 0 or 1)

    if actormode and a.x>=-128 and a.x<=0 and not a.spawner then
     for i=0,15 do
      pal(i,8-t\10%2)
     end
    end
   end
   if(not groupmode)dpal"0"

   i=objects[a.type]
   
   redir_multispr(a.spawner and "jump" or "idle",i,group.x+a.x,a.y)

   fillp()
   if(groupmode)circ(group.x+a.x,a.y,3,actormode and 8 or 2)

   if(a.spawner)print("spnr",group.x+a.x-7,a.y+4,7)

   dpal"0"
   --?a.group.."("..a.type..","..a.subtype..")",group.x+a.x,a.y,7
  end
 
  dpal"0"
 end



-- sky bg gradient
--[[
poke(0x5f5f,0x3e)
pal(skypal[sky],2)
memset(0x5f70,0xaa,16)]]

poke(0x5f5f,0x3e)
for i=0,15 do
local s=skypal[sky]
pal(i,s[i+1] or s[#s],2)
end
memset(0x5f70,0xaa,16)

if actormode then

 i=objects[actors[sel_actor]]
 if(i)redir_multispr(spawnermode and "jump" or "idle",i,mx,my)

end

pal(gamepal,1)

	camera()

 rectfill(0,0,127,11+(actormode and 6 or 0),0)
 palt(0,true)

	?"[space] kb: "..tmode.." -> "..seltileid[tmode],1,0,7

 ?"[tab] mouse: "..(actormode and ("group "..groupsel) or "groups")
 if(actormode)?"[z/x|q] "..(actors[sel_actor]).." | "..(spawnermode and "spawner" or "normal"),7
 if(tilemode)?"arrows: choose tile",7

 if my<24-80 then
	 for k,i in pairs(current) do
	  k-=1
	  print(chr(i+64),1+k%(128\4)*4,13+k\(128\4)*6+(actormode and 6 or 0))
	 end
 end

 bprint("SnAP: "..sn.."PX",1,122)

 -- copy world gfx
 memcpy(0,0xa000,0x2000)

 -- cursor
 pal(7,stat(34)==1 and 9 or (stat(34)==2 and 8 or 7))
 spr(0,stat(32)-1,stat(33)-1)
 pal(7,7)

 local ty=min(-sin(popt/120)*10,7)
 rectfill(0,128-ty,127,128,8)
 ?poptext,1,128-ty+1,7

end

_init=edit_init
_update=edit_update
_draw=edit_draw

function dist(dx,dy)
local maskx,masky=dx>>31,dy>>31
local a0,b0=(dx+maskx)^^maskx,(dy+masky)^^masky
if a0>b0 then
return a0*0.9609+b0*0.3984
end
return b0*0.9609+a0*0.3984
end

-->8
---[[
function save_data()

  --export_actors()
  flor=""
  bak=""
  bak2=""
  for i in all(floor) do
   flor..=chr(i+64)
  end
  for i in all(bg) do
   bak..=chr(i+64)
  end
  for i in all(bg2) do
   bak2..=chr(i+64)
  end


  if name and desc then
   str="{\nt="..name..","..desc.."\nd="..sky..","..flor..","..bak..","..bak2.."\n"
  else
   str="{\nd="..sky..","..flor..","..bak..","..bak2.."\n"
  end

  for g in all(groups) do

   str..="{\np="..g.x.."\n"

   -- organise group
   local types={}
   for a in all(g.actors) do

    -- add key
    local key=a.type
    if(a.stage and a.stage>1 or a.spawner)key..=","..a.stage
    if(a.spawner)key..=",".."spawner"
    if(not types[key])types[key]={}

    add(types[key],a.x..":"..a.y)

   end

   -- build string
   for k,t in pairs(types) do
    local s=k.."|"
    for i in all(t) do
     s..=i
     if i==t[#t] then
      s..="\n"
     else
      s..=","
     end
    end
    str..=s

   end

   str..="}\n"
  end

  str..="}\n"

  printh(str,"@clip")

end
--]]

--[[
function save_data()

  --export_actors()
  flor=""
  bak=""
  bak2=""
  for i in all(floor) do
   flor..=chr(i+64)
  end
  for i in all(bg) do
   bak..=chr(i+64)
  end
  for i in all(bg2) do
   bak2..=chr(i+64)
  end


  if name and desc then
   str="{\nt="..name..","..desc.."\nd="..sky..","..flor..","..bak..","..bak2.."\nl={\n"
  else
   str="{\nd="..sky..","..flor..","..bak..","..bak2.."\nl={\n"
  end

  for g in all(groups) do

   str..=""..g.x..";"

   -- organise group
   local types={}
   for a in all(g.actors) do

    -- add key
    local key=a.type..","..a.subtype
    if(not types[key])types[key]={}

    add(types[key],a.x..":"..a.y)

   end

   -- build string
   for k,t in pairs(types) do
    local s=k.."|"
    for i in all(t) do
     s..=i
     if i==t[#t] then
      s..=";"
     else
      s..=","
     end
    end
    str..=s

   end

   str..="\n"
  end

  str..="}\n}\n"

  printh(str,"@clip")

end
--]]
-->8
function popup(text)
 popt=popt==0 and 60 or max(popt,40)
 poptext=text
end

function redir_multispr(anim,this,x,y,dir)


 -- default to idle
 if not this[anim] then
  anim="idle"
 end

 local frame=this[anim][1]

 -- does frame exist?
 if frame and frame~="*" then
  -- handle redirects
  if not tonum(frame[1]) then
   frame=split(frame,":")
   frame=(frame[3] and objects[frame[3]] or this)[frame[1]][frame[2]]
  end

  -- draw frame
  multispr(frame,x,y,dir)
 end

end
-->8

function init_stage(id)

 local i=0

 local data=split(stgs[id].d,",",false)

 -- reset values
 got,cam_x
 =spread"0,64"

 -- cache group locations
 actor_groups={}
 for i in all(stgs[id]) do
  add(actor_groups,i.p)
  i.p=nil
 end

 sky,floor,bg,bg2=tonum(data[1]),charsplit(data[2]),charsplit(data[3]),charsplit(data[4])

end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
