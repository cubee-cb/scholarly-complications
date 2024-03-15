pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- beatem menu cart
-- yeah - cubee 🐱

load("beatem.p8","exit to title","nara,sine")

_btnp=btnp

#include beatem-init.p8l
#include beatem-data.p8l
#include beatem-levels.p8l

function _init()
reload(0,0,0x6000,"beatem.p8")

 loadconstants()
reload(0,0,0x6000,"beatem.p8")

 sky=3
	mode="splash"
	plrs=0
	maxplayers=2
	characters=split"nara,sine"

 local src,i=0xb800,0

 -- load wobblepaints
 while (%src>0) do
	i+=1
	wob[i]=wob_load(src)
	src+=%src
 end
end

cartdata"cubg-nara-game"

function _update()
if(debug)menuitem(4,"skip",function()level+=1 init_level(level,true) end)

-- compensate for 30fps
for lp=0,_update and 1 or 0 do
btnp=lp==1 and function()return end or _btnp

if mode=="splash" then
 if gt>150 or btnp(4) then
  fade()
  mode="title"
  sfx(-1)

  -- copy actor gfx
  memcpy(spread"0,0x8000,0x2000")
 end

 -- play pxlshk sound
 if t==32 then
  sfx(63)
 end

elseif mode=="title" then

 if(btnp(2))plrs-=1 ssfx(112)
 if(btnp(3))plrs+=1 ssfx(112)
 plrs%=maxplayers

 if btnp(4) then
  ssfx(113)
  fade()

  charsel,charconf,mode,countdown
  ={},{},spread"charsel,0"

  for i=0,plrs do
   add(charsel,i)
   add(charconf,false)
  end
 end

elseif mode=="charsel" then

 for i=0,plrs do
  local k=i+1
  if not charconf[k] then
	  if(btnp(0,i))charsel[k]-=1 ssfx(112)
	  if(btnp(1,i))charsel[k]+=1 ssfx(112)

	  charsel[k]%=#characters
  end

  -- confirm/cancel selection

	 local conf=true
	 for i in all(charconf) do
	  if(i==charsel[k])conf=false
	 end

  if btnp(4,i) then
   if conf then
    ssfx"113"
    charconf[k]=charsel[k]
   else
    ssfx"115"
   end
  end
 
  if btnp(5,i) then
   ssfx"114"
   if charconf[k] then
    charconf[k]=false
   else
    fade()
    mode="title"
   end
  end
 end

 local conf=true
 for i in all(charconf) do
  if(not i)conf=false
 end

 if conf then
  countdown-=1
  if countdown<=0 then
	  ssfx"116"
	  fade()

   -- add player actors
   for k,i in pairs(charconf) do
    add_actor("fighter",characters[i+1],32,24,k-1)
   end
   chara,mode=charconf[1],"game"

	  init_level(level)

	  
	  --music(0)
	  
	 elseif countdown%30==0 then
	  ssfx"117"
  end
 else
  countdown=plrs==0 and 0 or 120
 end

elseif mode=="fail" then
 if btnp(4) then
  fade()
  run()
 end
end


gt=max(gt+1)
fadet=max(fadet-0.02)

end
end
-->8


function _draw()

if pmode==mode then

pal()
cls(14)

palt(0,false)
palt(14,true)

if mode=="splash" then
 cls(0)
 local s=mid(0,1.5-((gt/20-3)/2)^2,1)
 sspr(0,0,32,40,64-flr(16*s),64-flr(20*s),32*s,40*s)

elseif mode=="title" then
 sky=5
 wob_draw"3"

 for i=1,maxplayers do
  bprint(i.." player"..(i~=1 and "s" or ""),10,112-maxplayers*8+i*8)
 end
 bprint(">",4,120-maxplayers*8+plrs*8)

elseif mode=="charsel" then
 sky=5
 wob_draw"3"

 local wide=112/#characters
 camera(wide-8,0)

 -- char boxes
 for k,i in pairs(characters) do
  local x,y,x2,y2=k*wide+1,8,k*wide+wide-2,88

  rectfill(x,y,x2,y2,0)
  local a=chars[i].anims["idle"]
  redir_multispr(a.frames[t*a.speed\10%#a.frames+1],i,k*wide+wide/2,80)

  bprint(split(chars[i].name)[1],x+11,y+3)

  rectfill(x,y,x+8,y+plrs*7+6,12)
  rect(x,y,x2,y2,12)
 end

 -- selection boxes
 for i=plrs,0,-1 do
  local k=charsel[i+1]+1
  local x,y=k*wide+1,8
  color(8+i)
  if(not charconf[i+1])rect(x,y,k*wide+wide-2,88)
  rectfill(x,y+i*7,x+8,y+i*7+6)
  ?"p"..i+1,x+1,y+1+i*7,7
 end

 camera()
 rectfill(spread"0,96,127,127,0")

 if(plrs>0)bprint("\^w\^t"..split"1,2,3,,"[countdown\30+1],61,32,9,4)

elseif mode=="fail" then
 cls()
 clip(spread"0,8,128,112")
 rectfill(spread"0,0,127,127,14")

 local xo,yo=sin(t/1000)*8-0.5,cos(t/810)*3-0.5

 sky=5
 wob_draw(3,xo/2,yo/2)

 wob_draw(chara+1,8+xo,4+yo)

	bprint("\^w\^tgame over",8-xo/2,97,8,2)
	bprint(levelname..": "..flr((cam_x2/(#floor*48)*100)+0.5).."%",8-xo/3,110,7)
end
end
	
	pmode=mode
	
-- sky bg gradient
poke(0x5f5f,0x3e)
for i=0,15 do
local s=skypal[sky]
pal(i,s[i+1] or s[#s],2)
end
--pal(skypal[sky],2)
memset(0x5f70,0xaa,16)

pal(gamepal,1)

camera()

-- fade overlay
if fadet>0 then
 for y=0,127 do
  line(128-fancyfade(fadet,y),y,128,y,0)
 end
 if fade_text then
  print(fade_text,66-#fade_text*2,(fade_text2 and 64 or 70)*(1/fadet)-8,7)
  if fade_text2 then
   print('"'..fade_text2..'"',62-#fade_text2*2,72*(1/fadet)-8,7)
  end
 end
else
 fade_text=false
 fade_text2=false
end

end
-->8
--wob
function wob_draw(scn,sx,sy,q)

 sx=sx or 0
 sy=sy or 0
 q=q or flr(time()*6)
 
 local funcs={[0]=
  circfill,circ,
  function(x,y,r,c)
   line(x-r,y,x+r,y,c) end,
	 function(x,y,r,c)
	  line(x,y-r,x,y+r,c) end,
  function(x,y,r,c)
   rectfill(x-r,y-r,x+r,y+r,c)
   end,
  function(x,y,r,c) -- star
		 a=nrnd(1)
		 for j=0,4 do
		  line(x,y,x+cos(a+j/5)*r,
		       y+sin(a+j/5)*r, c)
		 end
		end,
	 function(x,y,r,c,i) -- spin
		 local dx=cos(i*0x0.08)*r
		 local dy=sin(i*0x0.08)*r
		 line(x-dx,y-dy,x+dx,y+dy,c)
		end
 }
 
 local rv
 function nrnd(m)
  rv=rotl(rv,3)
  rv*=0x2518.493b -- mashed
  return (rv%m)
 end

 -- seed wobble by time
 srand(q)
 
 local xx=rnd(1)-.5
 local yy=rnd(1)-.5
 
 for j=1,#wob[scn] do
  local crv=wob[scn][j]
  
  local r,col,x0,y0=
  	crv.size,crv.col,
	  sx+crv[2] + xx,
	  sy+crv[3] + yy
	
  local x1,y1=x0,y0
  
  local shape,dotted,noise,pat=
	  crv.shape,
	  crv.dotted/3,
	  crv.noise/3,
	  crv.pat
	 
  if(dotted>0)dotted=max(1,flr(dotted*(1+r)/2))
  
  -- set pattern
  if((col/0x11)%1==0)pat+=0.5  
  fillp(pat)
  
  local sfunc=funcs[shape]
  
  -- random generator for noise
  -- seeded by curve number j
  rv=0x37f9.2407*j
  
  for i=2,#crv-1,2 do
   
   x0=x1 y0=y1
   x1=sx+crv[i]   +xx
   y1=sy+crv[i+1] +yy
   
   -- jump to another rnd
   -- offset closeby 
   -- (prevents crinkles)
   xx=xx*7/8+(rnd(1)-.5)/2
   yy=yy*7/8+(rnd(1)-.5)/2
   
   if (dotted>0) then
   
    -- one every nth point
    
    if ((i-2)/2)%dotted==0 then
     
     if (noise==0) then
      sfunc(x1,y1,r,col,i/2)
     else
     
     local mag=(r+2)*noise*2
     local smag=(r+1)*noise
     local r0=r-r*noise
     
     sfunc(
      x1 + nrnd(mag) - mag/2,
      y1 + nrnd(mag) - mag/2,
      r0 + nrnd(smag),
      col,i/2)
     end
    end
   elseif (shape==2) then
    -- wide brush (lettering)
    for i=flr(-r/2),flr(r+.5)/2 do
		   line(x0+i,y0,x1+i,y1,col)
		  end
   elseif (shape==3) then
    -- tall brush
    for i=flr(-r/2),flr(r+.5)/2 do
		   line(x0,y0+i,x1,y1+i,col)
		  end
   elseif (r<2) then
		  -- common
		  line(x0,y0,x1,y1,col)
		  if (r==1) then 
		  line(x0+1,y0,x1+1,y1,col)
		  line(x0,y0+1,x1,y1+1,col)
		  line(x0+1,y0+1,x1+1,y1+1,col)
		  end
		 else
		  -- cheap hack:
		  -- draw at control point
		  -- and at midpoint.
		  sfunc(x0,y0,r-1,col)
		  sfunc((x0+x1)/2,(y0+y1)/2,
		   r-1,col)
		 end   
  end
 end
 
 fillp()
 
end


-- decode

function wob_load(src)

 local src0=src
 src-=1 
 local bit,b=256,0
 local scn={}
 
 local function getval(bits)
  
  local val=0
  for i=0,bits-1 do
   --get next bit from stream
   if (bit==256) then
    bit=1
    src+=1
    byte=peek(src)
   end
   if band(byte,bit)>0 then
    val+=2^i
   end
   bit*=2
  end
  return val
 end
 
 local dat_len = getval(16)
 local lsize,lcol
 
 -- back color
 scn.back_col=14
 
 -- read state
 local col,size,shape,dotted,
       noise,pat=
       0,0,0,0,0,0
 
 -- read until out of data
 -- each item is >= 3 bytes
 while (src<src0+dat_len-3) do
 
  -- curve header (3 sections)
  -- 1. 
  local crv=add(scn,{0})
  
 -- {0} --dummy

  if (getval(1)==1) then
   col,size=getval(4),getval(5)
  end
  
  if (getval(1)==1) then
   shape,dotted,noise=
   getval(3),getval(4),getval(3)
  end

  -- set state
  crv.col,crv.size,crv.shape,
  crv.dotted,crv.noise,crv.pat=
  col,size,shape,dotted,noise,0
  
  -- use pattern
  if (getval(1)>0) then
   crv.pat=getval(16)
   crv.col+=getval(4)*16
  end
  
  -- 7 start x,y
  add(crv,getval(7))
  add(crv,getval(7))
  local x0,y0,has_segs,a=
   crv[2],crv[3],getval(1),0
  
  -- read segments
  
  while (has_segs>0) do
   local v=0
   
   if (getval(1)<1) then
    -- read non-zero da
    local neg=getval(1)
    v=1
    while(getval(1)<1 and v<8)
    do v+=1 end
    if (neg>0) v*=-1
   end
   
   if (v==8) then
    -- end of segment
    has_segs=0
   else
    -- add segment
    a+=v
    x0+=flr(.5+cos(a/16)*3)
    y0+=flr(.5+sin(a/16)*3)
    add(crv,x0)
    add(crv,y0)
   end
  end
 end

 return scn
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
