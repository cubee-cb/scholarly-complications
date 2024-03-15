pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
-- beatem multispr editor
-- by cubee 🐱

--encodemode=true

--[[

    edit multisprs visually!
( TOOK ME WAY TOO LONG TO GET )
( AROUND TO... anyway         )

use kb+mouse
esdf in select mode to shift
global offset

h flips the sprite, editing
remains as is to remind you that
it's still flipped and also meh, i'm not fixing it

supports copy-paste of strings
and pasting multiple sprites

]]

#include beatem-init.p8l
#include beatem-data.p8l
#include beatem-levels.p8l

function multispr(str,x,y,flip,scale)
 scale,str=scale or 1,split(str,"|")

 for sp in all(str) do

  local i,w,h,sx,sy,r,s=spread(sp,":")
  r,s=r or 0,s or 1
  if(flip)sx,r=-sx,-r
  local sc,tx,ty=scale*s,flr(x+sx*scale),flr(y+sy*scale)

  -- draw
  if r==0 then
   local tw,th=ceil(w*8*sc),ceil(h*8*sc)
   sspr(i%16*8,i\16*8,w*8,h*8,tx-tw*.5,ty-th*.5,tw,th,flip)
  else
   --put into map
   for ix=0,w+1 do
    for iy=0,h+1 do
     mset(ix,iy,(ix<w and iy<h) and (i+ix+iy*16) or 0)
    end
   end
   rspr(tx,ty,r,0,0,w,h,flip,sc)
  end

 end

end

pal(split"133,2,137,4,5,6,7,8,9,3,142,130,134,140,143",1)
poke(0x5f2e,1)

function _init()
 t=0

 showsel=true

 sy=96

 menuy=0

 spr={
  "0:1:1:0:-18:0"
 }
 sel=0
 
 sprs_sel=0
 sprs={spr}
 
 base="0:1:1:0:0:0"
 part=split(base,":")

 debug=true

 menuitem(1,"get actor gfx",function()
  reload(0,0,0x2000,"beatem-gfx-actors.p8")
  cstore(0,0,0x2000)
 end)

 -- enable devkit mode
 poke(0x5f2d,1)
end

function _update60()
 mx,my=stat(32),stat(33)

 ignoremode=false

 while stat(30) do
  k=stat(31)

  if(k=="[")sprs_sel-=1 movemode=false
  if(k=="]")sprs_sel+=1 movemode=false

  if(k=="h")flipspr=not flipspr

  if k=="\b" and #spr>1 then
   deli(spr,sel+1)
  end

		-- copy to @clip
  if k=="る" then

		 local str=""
		 --if(type(label)=="string")str..=label.."="

		 for k,spr in pairs(sprs) do


   if not encodemode then
			 for k2,i in pairs(spr) do
			  local a=split(i,":")
	
			  -- del rot val if scale doesn't exist
			  if(#a==6 and a[6]==0)deli(a,6)
			  local s=""
			  for b=1,#a do
			   s..=a[b]
			   if(b<#a)s..=":"
			  end
			  str..=(tonum(k2) and k2>1 and "|" or "")..s
			 end
			 str..=""
			 if(k~=#sprs)str..="\n"

   -- encodemode
			else

			--
			 for k2,i in pairs(spr) do
			  local a=split(i,":")
	
			  -- del rot val if scale doesn't exist
			  local s=""
			  for b=1,7 do
			   if(b==6 and a[b])a[b]%=1
			   s..=chr((a[b] or (b==6 and 0 or 1))*split"1,1,1,1,1,100,100"[b]+split"0,0,0,128,128,0,0,0,0"[b])
			  end
			  str..=escape_binary_str(s)
			 end
			 if(k~=#sprs)str..="\n"


   end--encodemode

			end

		 printh(str,"@clip")

   ignoremode=true
  end

  sprs_sel%=#sprs
  spr=sprs[sprs_sel+1]

  -- read pasted sprites
  if k=="コ" then
   
   sprs=str2table(stat(4))
   for i=1,#sprs do
    sprs[i]=split(sprs[i],"|")
   end
   sprs_sel=0
   spr=sprs[sprs_sel+1]
   --[[
   for k,i in pairs(spr) do
    spr=i
    label=k
   end]]
   part=split(base,":")
   movemode=false
   menu=false

  end

 end

 if(btnp(5) and not ignoremode)movemode=not movemode

 if menu then

  hovspr=mx\8+my\8*16

  if(btnp(4))menu=false newpart=false

  if stat(34)==1 then
   if(menu~=1)selspr=hovspr

   selw=mx\8-selspr%16+1
   selh=my\8-selspr\16+1

   menu=1

  elseif menu==1 then
   menu=false
   part[1]=selspr
   part[2]=selw
   part[3]=selh
   wasmenu=not movemode
   movemode=true

   if newpart then
    sel=#spr
    add(spr,base)
   end

   newpart=false
  end

 elseif movemode then

  -- edit part gfx
  if(stat(34)==2)menu=true

  -- leftclick
  if stat(34)==1 then
   -- reset rot
   if mx>=92 and my>=122 then
    part[6]=0

   -- move part
   else
    part[4]=mx-64
    part[5]=my-sy
   end
   if(wasmenu)wasmenu=1
  elseif wasmenu==1 then
   movemode=false
   wasmenu=false
  end

  -- rot
  if btn(4) then
   if(not part[6])part[6]=0
   if(btnp(0))part[6]-=0.125
   if(btnp(1))part[6]+=0.125
   if(btnp(2))part[6]-=0.01
   if(btnp(3))part[6]+=0.01

   -- workaround for precision issues
   part[6]=(flr(part[6]*1000+0.5)/1000)%1
  else
   if(btnp(0))part[4]-=1
   if(btnp(1))part[4]+=1
   if(btnp(2))part[5]-=1
   if(btnp(3))part[5]+=1
  end
  
  scroll=stat(36)/10
  if scroll~=0 then
   if part[7] then
    part[7]+=scroll
    if(tostr(part[7])=="1")deli(part,7)
   else
    if(not part[6])part[6]=0
    part[7]=1+scroll
   end
  end

  if part[7] then
   -- workaround for precision issues
   part[7]=(flr(part[7]*100+0.5)/100)
  end

 else
 
  local o={0,0}
 
  if(btnp(0,1))o[1]-=1
  if(btnp(1,1))o[1]+=1
  if(btnp(2,1))o[2]-=1
  if(btnp(3,1))o[2]+=1

  applyoffset(o)

  selspr=0
  selw=1
  selh=1

  if(btnp(0))sel-=1
  if(btnp(1))sel+=1
  sel%=#spr

  -- new part
  if stat(34)==2 then
   menu=true
   newpart=true
  end

  part=split(spr[sel+1],":")
 end

 str=""
 for i=1,#part do
  str..=part[i]
  if(i~=#part)str..=":"
 end
 spr[sel+1]=str

 if(btnp(4,1))showsel=not showsel

 t=max(t+1)
end

function _draw()
 cls(14)

 palt(0,false)
 palt(14,true)

 camera(-64,-sy)

 local str=""
 for k,i in next,spr do
  if(tonum(k)) then
  if(k>1)str..="|"
  str..=i
  end
 end
 multispr(str,0,0,flipspr)
 pset(0,0,7)

 local a=part[6] or 0
 local partscale=part[7] or 1
 local w,h=part[2]*partscale,part[3]*partscale
 --local h,w=cos(a)*h-sin(a)*w,cos(a)*w+sin(a)*h

 local x,y=part[4]-w*4,part[5]-h*4
 if(showsel)rect(x-1,y-1,x+w*8,y+h*8,6)

	camera()

	?movemode and "editing part\nright click: edit gfx\n🅾️: rotate part | ❎: go back" or "selecting part\nright click: add new part\n❎: edit part",1,1,7
	?((btn(4) and movemode) and "⬆️⬇️ precise | ⬅️➡️ 45 degrees" or "").."\n"..split(str,"|")[sel+1]

 ?(sprs_sel+1).."/"..(#sprs),1,122-6
 ?"ctrl+c to copy",1,122

 ?movemode and "reset rot" or "",92,122,mx>=92 and my>=122 and 8 or 2

 if menu then
  cls(14)
  sspr(0,0,128,128,0,0)

  local x,y=selspr%16*8,selspr\16*8
 
  rect(x-1,y-1,x+selw*8,y+selh*8,6)

  if(my>128-16)menuy=0
  if(my<16)menuy=121
 
  rectfill(0,menuy,127,menuy+6,newpart and 8 or 1)

  ?(newpart and "adding new part" or "changing sprite"),1,menuy+1,7
 end

 -- linemouse :)
 function curs(mx,my,c)
  line(mx,my,mx,my+3,c)
  line(mx,my,mx+2,my+2,c)
  line(mx,my+1,mx+2,my+4,c)
 end
 for ix=-1,1 do
  for iy=-1,1 do
   if(abs(ix)+abs(iy)~=2)curs(mx+ix,my+iy,1)
  end
 end
 curs(mx,my,7)

 --printh(k,"@clip")

 if(encodemode)print("binary export mode",17,116,8)

end

-->8
function applyoffset(o)
 for i=1,#spr do
	
	 local s=split(spr[i],":")

	 s[4]+=tonum(o[1]) or 0
	 s[5]+=tonum(o[2]) or 0
	
	 local st=""
	 for k,a in pairs(s) do
	  st..=a
	  if(k~=#s)st..=":"
	 end
	 
	 spr[i]=st
	
	end

end

-->8
--zep escape binary string
--https://www.lexaloffle.com/bbs/?tid=38692

function escape_binary_str(s)
 local out=""
 for i=1,#s do
  local c  = sub(s,i,i)
  local nc = ord(s,i+1)
  local pr = (nc and nc>=48 and nc<=57) and "00" or ""
  local v=c
  if(c=="\"") v="\\\""
  if(c=="\\") v="\\\\"
  if(ord(c)==0) v="\\"..pr.."0"
  if(ord(c)==10) v="\\n"
  if(ord(c)==13) v="\\r"
  out..= v
 end
 return out
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee55eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55000eee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ea0000ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5ad000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee5a0d0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeee5aee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44442eeeccccceeeeee4eeeeeeeeeeeeee444eeeeeeeeeeeeeeeeeee000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
44422eeecc2c2eeeeee244eeeaaeeeeee442242aa5aa5eeeeeeeeeee000000000000000000000000eeeeeeeeeeeeeeeeeeeee5deeeeeeeeeeeeeeeeeeeeeeeee
2442eeeec2c2eeeeeee2244442aaeeeee42e24445a55cc5a5eee422e000000000000000000000000eeeeeeeeeeeeeeeeeeeee55eeeeeeeeeeeeee0cccceeeeee
e442eeeee252eeeeeeee4424444eeeeee42ee44444aa58c5aa544222000000000000000000000000eeeeeeeeeeeeeeeeeeeeee11eeeeeeeeeee0c0000cc0eeee
e2442eeeee25eeeeeeee54662444eeeee4ee444424445aaa54444222000000000000000000000000eeeeeeeeeeeeeeeeeeeeee15eeeeeeeeee000015100c0eee
ee44444eeee25eeeeeee5a4777445eeee4ee44444222444444424422000000000000000000000000ee0ccccc0ee22442eeeeee111eeeeeeeee00e55e51e0ceee
eee24442eee5aeeeeeee25a5aaa2a50e42ee44444422222224442422000000000000000000000000eee000cccc02444444420ccc0eeeeeeee0005eddde10ccee
eeee2c2ceee225eeeeeee2a065aaa00042ee44444422222244442221000000000000000000000000eeeeee000cc022244422000ccc0eeeeee00d51555d510cee
ee44422eee222ccceeeeeeeee255aa5542ee24444221222244442211000000000000000000000000eeeeeeee00000022222cc000cccceeeee005e1555de50cee
ee44222eee22ccceeeeeeeeeee6e26ee2eeee444222111224442211e000000000000000000000000eeeeeeeee0000cc1111c1cc0000ceeeee00d51555d5100ee
e44422eee222cceeeeeeeeeeeeeeeeeeeeeeee4222eee111242211ee000000000000000000000000eeeeeeeeeecc1515555151ecc100eeeee0005e111e5000ee
e2422eeeec2cceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000eeeeeeeeecc1115155151eec15eeeeeeee00e55e55e00eee
ee442eeeee22ceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000eeeeeeeeeccc115dd155ceee151eeeeeee0000d5d0000eee
ee4444eeee2222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000eeeeeeeedddd5cdd6d1ceeeec15eeeeeeee000000000eeee
ee24442eeec222ceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000ee5d5ddddd55c244ddeeeeeee15eeeeeeeeee00000eeeeee
ee22c2ceeeccc0ceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000ee55155555eeee224eeeeeeee11eeeeeeeeeeeeeeeeeeeee
eebbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee442e442eeeeeeeee442eeeeeeeeeeeaa5eeeedceeeeeeaa5eee88888888cccccceeecccccccee55551e
e9bbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444444444eeeeeee44442442eeeeeaaaaa5eeeedc11eea5aa66e888888881c1ccceeeccccc11e1555551
399ba3eeeee39eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444444242eeeeee444444444eeea55aaa51eeed5ceea55a6226888888881111cceeeccccc11e5555511
3399993eee3999eeeee33eeeeeeeccceeeccceeeeee2444442222eeeeee24444444242eeaaaa6226eed5c5eeaaaad55d88888888c111cceeeccccc11e5555511
3399999eee9933eeee3333eeeeec111ce11cceeeeee4442222b222eeeee4442442222eee5aaa5aa1dd5c11ee5aa560068888888811111cceeeccc11c15555111
e339999eee933eeeee3333eeeee1111ce111cceeee244222bbfd22eeee24422222b222ee55a5d00d5cc5c1ce55a00000888888881111ccceeecc111c55555111
e339993eeeba3eeeee3333eeeee111cce111cceeee44222bdaf68aeeee442222dbfd22ee15556556ec11eeee1550ccc0888888881111ccceeecc111c5551111e
3339933eeefbaeeeeee355aeeee111ccee11cceeee2422ba6855a5eeee2422bb6af68aeee15e511eeeeceeeee1556c06888888881111ccceec11111c555511ee
333393eeeefa1eeeeee55afeeec11cccee11cbeeee222bab2a000feeee222b5aa855a5eeeeeecdeeddeeeeee8888888888888888c1111ccce11111cc155511ee
333333eeeeb81eeeeeee5baeee111ccceec1bfeeeee22b58a000beeeeee22b5b26d6dfeee11cdeee55ddeeee8888888888888888cc11cccc111111cc155511ee
333333eeeeac8eeeeeeeb5aeee11ccceeec11bbeeeee2225000eeeeeeeee22b85d6dbeeeeec5deeeecc5deee8888888888888888ec111cccc111ccce111111ee
333333eeee18ceeeeeeebbfee111cceeeee11cceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5c5deeec15deee8888888888888888ecccccccccccccce1777766e
ccccceeeee228eeeeeeebbffec1ccceeeeec11cceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee11c5ddc55c1dee8888888888888888e00000cccc00000e7766666e
e11ceeeeeee22eeeeeeebbbf1c000eeeeeecc00ceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeec1c5cc5eec155ee88888888888888880ccc000000ccc0006666666e
eeeeeeeeeee2eeeeeeeeebbb00cc00eeeeee0c00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee11ceec15ccee88888888888888880c00000000c00000e66666ee
eeeeeeeeeeeeeeeeeeeeebbe000000eeeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeceeeeeeec11e88888888888888880000000000000000eeeeeeee
eebbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddcccccccccccccceeeeeeeeeeeabbeeeeeeeeedddd5e5ddee
eabfbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedd55ccccccccccccccceeeeeeeeeaabbbeeeeeeed5d55aa555ee
39aaf3eeeee5eeeeeeeaaeeeeeeeeeeeeeeeeeeeeeeee4444442eeeeeeeee444442eeeeeeeed5cceccccc1111cccccceeeeeee5aa5bbbeeeeedd55aaaaaa22ee
339a5b9eee5a5eeeee5a5eeeeeeeeeeeeeeeeeeeeee2444444442eeeeee244444442eeeeeeed51cecccc111ccccccceee111551a5aab1eeeee55daa5aa5a5eee
3399399eeeaa5eeeee55aeeeeeeeeeeeeeeeeeeeeee4444444422eeeeee4444444422eeeeed1c55ccccccccccccceeee1111155285a815eeee5ddadd55b5ddee
3399999eeeaa5eeeee5252eeeeeeeeeeee3eeeeeee24444442222eeeee24444444422eeeee551ceeeccccccccceeeeee111115512882551eeee5daad66fd6aee
e339993ee5a55eeeeee828eeeeeee3eee333eeeeee44444422b22eeeee44444442222eeeeecc51ceeccccccceeeeeeee11111555d28d555eeee55dbbfffbbaee
e33333eeeaabeeeeeeed2eeeeeee333ee3335eeeee4444422b002eeeee44444222222eeee11ceeeeeeeeeeeeeeeeeeee1111555568dd555eeeeaaa20d6d66eee
e7cc7ceeeab5eeeeeeee1eeeeeebb33ee5aa5eeeee4444222bad2eeeee4444222b002eee88888888eeeeeeeeeeeeeeee11155555686d551eeee550000000eeee
e7c1c1ceea5beeeeeee822eeeeebbbbee5a55eeeee24422200260eeeee2442225b260eee88888888eaa5ffeee5a5ffee11555551688d151eeee5a500000eeeee
7cc1c1ce5bbfeeeeee822feeeeeffbbeee5a5eeeee22422200052eeeee224222a0052eee88888888aaa5bfbe5aaabfbe11555551288d111eeeeaa5ccccceeeee
7c71c11eb5bbfeeeeeb2bfbeeebffbeeee5a55eeeee2222eee22eeeeeee2222eee22eeee88888888a555ffbeaaaa5abb11155551888d111eeee5aac6c6d6eeee
7c7c1c1cfbfebeeeeebbfebeee66ddeeee66ddeeeeee22eeeeeeeeeeeeee22eeeeeeeeee8888888855fffb4eaaaaaab4e1115512882d11eeeeeeaa2bfffbaeee
77c7c7c7efbeeeeeeeebbeeee6dcceeeeedd77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88888888a1abb45e51a15154e111111228dd11eeeeeee2222fba5eee
eeeeeeeeeeeeeeeeeeeeeeeeecc1cceeee77c77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888885151a55e5151555ee111111222c11eeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeccccceeee77777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88888888e51515eee51515eeee1111c22cc11eeeeeeeeeeeeeeeeeee
eeeec1111ceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2442eeeeeeeeeeeeeeeeeeec22222ceeeeeeeeec22222ceeeeeeeeeeeeeeeeeeeeeebbbbe
eee11111111cceeeeeee67eeee66eeeeeeee7762266eeeeee776eee44442eeeeeeeeeeeeeeeee2222c222ceeeeeee2222222ccceeeeeeeeeeeeeeeeee39bbbbe
eec111ccccccceeeeee7777ee6666eeeeeee762446eeeeee77777ee24422eeeeeeeeee0eeeeec222c222cceeeeee22c222ccccceeeeeeeeeeeeeeeee3999bb93
ee111ccccc2eeeeeee77777eed666deeeee7776c177eeeee777776ec2222eeeeeeeee0eeeeee222cc222cceeeeec2c222cccbceeeeeeeeeeeeeeeeee33999999
ee111c222222eeeee67776eeee6666eeeee77760177eeeeee6677777dcceeeeeee1e01eeeeec222c222ccceeeee22c22ccbbbcceeee399eeeeeeeeee43999999
ee11c2244444eeeee7776eeeeed666deeee777701076eeeeee666667766eeeeeee5ee5eeeee222cc222cceeeee22c22ccbbffcceee9999eee439eeee43399993
eec1c244111c4eee67766eeeeee666deeee7777c9377eeeeeee6666666eeeeeeeeeeeeeeeee22ccc22cccfeeee22c22cbbbfffcee99993eee4439eee4333333e
eeccc241444c4eee7776eeeeeeed66deeee677763376eeeeeeeed66deeeeeeeeeeeeeeeeeee2ccc22cccbfeeecccc2cbbbfffbeee3933eeee4433d5e4334443e
eeccc241444c2eee6766eeeeeeeddddeeeee7777cc76eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccccc2cbbbbbeeeeeccccbbbffbbceb333eeeee444ddd5c433333e
eeeccc2cccc2eeee6666deeeeeddddeeeeee7777c166eeeeeeeeeee0eeeeeeeeeeeeeeeeeeeeccccccbbbeeeeeeeccccbbbbbceefbb5eeeeeebbdddd0c43334e
eeeeeeeeeeeeeeeee6666deeee11ddeeeeee7776c166eeeeee0eee0eeeeeeeeeee0eeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebf55eeeeeebb5dd510cc6dce
eeeeeeeeeeeeeeeeeeddcceeee221eeeeeee6776c166eeeeeee0ee1eeeeeeeeeeee0ee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee555ddeeeeeebbd55511111ee
eeeeeeeeeeeeeeeeeecc22eeee2222eeeeee6766ccd6deeeee000e5ee00eee00eee10e1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5ddd5eeeeeeee55ee5551eee
eeeeeeeeeeeeeeeeee2242eeee2222eeeeee666d111dddeeeeeeeeeeee11e11eeee5ee5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddd55eeeeeeeeeeeee511eee
eeeeeeeeeeeeeeeee44442eeeee222eeeee66d555511eeeeeeecceeeeeeeeeeeeeeecceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5d55eeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee2442eeeeeeeeeeeeeee55ee555eeeeeeee22ceeeeeeeeeeeeec22eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee55eeeeeeeeeeeeeeeeeeeee
eeeeec1111ceeeeeeeeeddd5155555eee5ddd5eee55555eeed542eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeec22222ceee
eeec1111111ceeeeeeeeddd5115555eeedddd5eee15555eeed2441551e111eeeeeeeeeeeee5dd5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22c22222cce
ee11111cccccceeeeeeedd55115555eeedddd5eee15555eee5244555555511eeee99999bbf55dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22c22222ccce
ee111cccccccceeeeee5dd55115555eeedddd5eee11555eed5442155555111eeee33993bff55dd5eeeeeeeee51eeeeeeeeee5511cccceeeeeeec2c2222ccccce
ee11cc222222eeeeeeeddd55111555eeeddd55eee11511ee5242211155111eeeee33333bbb55555eeee399ee555eeeeeeee15551ccccceeeeee22c222cccbcee
eec1c2244444eeeeeee55d55111511eeedd555eee11515ee5222e1111111eeeeeeee333eee5e555eee9999ee5551eeeeeee55551cccc1eeeeee2c222ccbbbcce
eec1c24111144eeeeee5dd55e11515ee5dd555eee11555eee22eeeee111eeeeeeeeeeeeeeeeeeeeee99993ee1555eeeeeee55551ccc11eeeee22c22ccbbfffce
eeccc24144cc4eeeeeedd555e11555eedddd5eeee11555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb3933eee15555eeeeee15551ec111ceeee2cc22cbbffffce
eeccc241444c2eeeee5dd55ee11555eeddd55eeee11151eeeeeeeeeeeeeeeeee1111111ceeeeeeeef335d5ee11551eeeee155511ec1111eeeccccc2bbffffbee
eeeccc2ccccceeeeeeddd55ee11151ee5dd55eeee11111eeeeeeeeeee5421115111111111112ceeebb55ddee1151142eee55551eecc11ceeeeeeccccbbbbbcee
eeeeeeeeeeeeeeeeee5d555ee11111ee55555eeee1111ceeeeeeeeeed444555151ccc11111c22ceeeb5dddeee1144422e155111eecc2222eeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeee55555ee111ccee55555eeee11cc11ceeeeeeeed2441555551cccc11122cc1ee5ddd5eee44442d5e24442eeeccc222ceeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee111111eeccc111e55111eeeecc111cceeeeeeee5d242155511eccccc122c11cee5d55eee242d511e224442eeccccccceeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee555101eec0c111111555eeeec0cccceeeeeeeeeed244455111eeeeccc22c111eee55eeee22d111ee222222ee1115551eeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee5551101eec0cc1cc101555eeec0cceeeeeeeeeeee552421111eeeeeeecccc11eeeeeeeeeed511eeee55ddd5eeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee1511eeeeeeeeeeee101151eeeeeeeeeeeeeeeeeeeee5d5eeeeeeeeeeeeecc1ceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeee0eeeeeeeeeeeeeeee00eeeeeeee00e888888888888888888888888888888888888888888888888eeeee144dd444444eeeeeeeeeeeeeeee111ccccc
eeeeeeeeeee00eeeeeeee00eee0eeeeeeeeeeee0888888888888888888888888888888888888888888888888eeee144444444444eeeeeeeeeeeeeeeee441c1ce
e00eeeeeeee1ee00ee00ee10eee1e000ee00ee1e888888888888888888888888888888888888888888888888eee414dd4ddd44441111551155111111ee141cee
ee00e000eee5ee5eeee00e5eeee5ee5eeee00e5e888888888888888888888888888888888888888888888888ee414444444444444444111411444441eeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888888888888888888888888888888888888888888888e114444d4444444411111cc11cc11115eeeeeeee
eeee00eeeee0eeeeeee00eeeeee0eeeeeee0eeee888888888888888888888888888888888888888888888888144dd4d444444455eeeeeeeeeeeeeeeeeeeeeeee
eee0eeeeeeee0eeeeee220eeeeee0eeeeeee00ee8888888888888888888888888888888888888888888888884444444444451544eeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888888888888888888888888888888888888888888888ddddd44d44444444eeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeee42eee77eeee88888888888888888888888888888888eeeeeeeeeeeeeeee8888888888888888eee1ceeeeeeeeeeeeeeeeeee
eeeee6622676eeeeeeeeeeeeeeee4442e6777eee88888888888888888888888888888888eeeeeeddddeeeeee8888888888888888eee41eeeeeeeeeeeeeeeeeee
eeeeee6442776eeee7777777766c4422e7777eee88888888888888888888888888888888eeeeeeddddeddeee8888888888888888eee41eeeeeeeee6dd5eeeeee
eeeeed711c6776ee77777777776c2422e7776eee88888888888888888888888888888888eeeddddddddddeee8888888888888888eee41eeee66dd6111d5dd66e
eeeeed76106776ee77777666666c222e67776eee88888888888888888888888888888888eeddddddddddddee8888888888888888eee41eeeddddddddddddddd6
eeeee6700c7776eee6666666666dc22e7777eeee88888888888888888888888888888888eedddddddddddddd8888888888888888eee41eee5dddddd666666665
eeeee793cc7776eeee66deeeeeeeeeee7777eeee88888888888888888888888888888888eedddddddffffeee8888888888888888eee41eee1155555555555511
e42ee733c6776deeeeeeeeeeeeeeeeee6776eeee88888888888888888888888888888888eedddddffffffeee8888888888888888eee1ceeee11111111111111e
2442c76c17766eee00000000000000006776deee88888888888888888888888888888888edddddbbbffbbfeeeeeeeeeeeeeeeeeeeeeeccceee551111111155ee
444cd76c1776deee0000000000000000e77666ee88888888888888888888888888888888eddddd7c7ff7c7eeeeeeeeeeeeeeeeeeeeee22ceed000000000000de
242c76c16776eeee0000000000000000e6766dee88888888888888888888888888888888eddddfffffffffeeeeeeeeeeeeeeeeeeeeee822ee5d5000000005d5e
e22676c17776eeee0000000000000000ee6dccee88888888888888888888888888888888eddddfffbbbbbfeeeeeeeeeeeeeeeeeeeeee8c2ee55dddddddddd51e
eee776cc676deeee0000000000000000eecc24ee88888888888888888888888888888888eeddefffff88ffeeeeeeeeeeeeeeeeeeeeee82eee5d555555555551e
ee766111d66deeee0000000000000000ee2244ee88888888888888888888888888888888eeeeeeefffffeeeeeee888882eeeeeeeeee282eee5d5d5d5d5d5d55e
eeee115111dddeee0000000000000000ee2444ee88888888888888888888888888888888eeeeeeeeeeeeeeeeee288888828eeeeeeee882eee5d5d5d5d5d5d55e
eeeee5ee5511eeee0000000000000000eee242ee88888888888888888888888888888888eeeeeeeeeeeeeeeeee82222288228eeeeee882eee5d5d5d5d5d5d51e
eeeee55eeeaa42eeee9cccc4eeeee55eeeeeeeee888888888888888888888888888888888888888888888888e28c00008822228eeee822eee1d5d5d5d5d5d51e
eeee2825e825aa5e9cc1194eeeee2825eeeeeeee888888888888888888888888888888888888888888888888e828888828c2222eee882ceeeed5d5d5d5d5d5ee
ee2998222888222e49999424ee266822ebf82fbe888888888888888888888888888888888888888888888888e828222822ccc222ee282eeeeed5d5d5d5d5d5ee
e888932c8ff8f821e4422222e2886d2cfff22fff888888888888888888888888888888888888888888888888e828888822ccccc2ee882eeeeed5d5d5d5d5d5ee
555822c28f8888824d66dd42241822c1bfffffbb888888888888888888888888888888888888888888888888e228888822ccccc2ee882eeeeed5d5d5d5d5d5ee
dd522c2e2888882299dd6942424ccc1edb4b4b45888888888888888888888888888888888888888888888888e2c22222c2ccccccee282eaeee55d5d5d5d555ee
5dd5c2ee228882214999944e2442c1ee5d5ddd51888888888888888888888888888888888888888888888888eecccc00002ccccca2c2caa5ee1555d5d55551ee
e5552eeee22e211ee244422ee2211eeee51d551e888888888888888888888888888888888888888888888888eeeeeccc000022c25ca5a5eeeee1555555511eee
