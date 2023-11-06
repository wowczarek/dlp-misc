{$D-}
program spaceworm;
uses crt;
const
slowdown=0; ilen=5; blen=1;
maxx=50; maxy=10;
type
sounds=(die,pau,unp,eat,lup);
var
gacc,gacc1,lbn,hcap,bx,by,dx,dy,tx,ty,hx,hy,fx,fy,grow,dc,dly:integer;
idly,dlystep,ihcap: integer;
pts,len: word; col:boolean; f,chd,lv:byte;
{ simple delay loop }
procedure delay(d:integer);
var i: integer;
begin;
 i:=0; repeat inc(i) until i=d;
end;
{make sounds!}
procedure squeak(s:sounds);
var
i: integer;
begin
 case s of
  die: begin i:=800; while i>400 do begin sound(i,5); dec(i,5); end; end;
  pau: begin sound(500,25); sound(700,25); sound(900,50); end;
  unp: begin sound(900,25); sound(700,25); sound(500,50); end;
  eat: begin sound(600,25); sound(800,50); end;
  lup: for i:=300 to 350 do sound(i,5);
  end;
end;
{ set score and display it}
procedure score(s: word); 
var st:string;
begin
 pts:=s; str(pts,st); while length(st) < 5 do st:='0'+st;
 gotoxy(27,1); write('$'+st);
end;
{erase tail}
procedure et;
var
dir: byte;
begin
 bx:=tx+tx+tx; by:=ty+ty+ty;  { look ma, no multiplication! }
 { read 4 pixels around tail point, 3 should be empty, single bit set = tail's direction }
 dir := point(bx,by-1) + point(bx,by+2) shl 1 + point(bx+2,by) shl 2 + point(bx-1,by) shl 3;
 case  dir of  { erase both horizontal / vertical separators, advance tail }
  1: {u} begin plot(bx,by-1,0); plot(bx+1,by-1,0); plot(bx,by+2,0); plot(bx+1,by+2,0); dec(ty); end;
  2: {d} begin plot(bx,by-1,0); plot(bx+1,by-1,0); plot(bx,by+2,0); plot(bx+1,by+2,0); inc(ty); end;
  4: {r} begin plot(bx-1,by,0); plot(bx-1,by+1,0); plot(bx+2,by,0); plot(bx+2,by+1,0); inc(tx); end;
  8: {l} begin plot(bx-1,by,0); plot(bx-1,by+1,0); plot(bx+2,by,0); plot(bx+2,by+1,0); dec(tx); end;
 end;
 { erase tail segment }
 plot(bx,by,0);  plot(bx+1,by,0); plot(bx,by+1,0);  plot(bx+1,by+1,0);
end;
{draw head}
procedure dh;
begin
 bx:=hx+hx+hx; by:=hy+hy+hy;
 case dx+dy+dy+3 of  { draw separator: simple hash function to code direction }
  1: begin plot (bx,by+2,1); plot(bx+1,by+2,1); end; {d}
  2: begin plot (bx+2,by,1); plot(bx+2,by+1,1); end; {l}
  4: begin plot (bx-1,by,1); plot(bx-1,by+1,1); end; {r}
  5: begin plot (bx,by-1,1); plot(bx+1,by-1,1); end; {u}
 end;
 { draw head segment }
 plot(bx,by,1); plot(bx+1,by,1); plot(bx,by+1,1); plot(bx+1,by+1,1);
end;
{ advance a level}
procedure lvup;
begin
 inc(lv); gacc:=ilen; gacc1:=ilen;{ start growth accumulator from scratch}
 dly:= dly - idly div dlystep + hcap + slowdown;  if dly<=0 then dly:=0;
 { base is 10 food per level + door + extra to fit the curve }
 f:=11; if lv>5 then inc(f); if lv>8 then inc(f); if lv>9 then inc(f);
 { the curve is 10,15,20,25,30,40,50,60,75,100 % of max length per lv }
 gotoxy(27, 2); write('lvl:',lv); gotoxy(27, 3); write('obj:',f-1); if f < 11  then write(' ');
 while len>blen do begin et; display; dec(len); end;
end;
{ wait for keypress }
procedure waitkey;
begin
 repeat until keypressed;
 { consume both codes if got a two-code key }
 if (readkey=#0) and (readkey=#0) then exit;
end;
{ pause game }
procedure pause;
var i: integer; c:char;
begin
 i:=0; squeak(pau);
 repeat { flash 'Pause' }
  if i=0  then begin gotoxy(27,4); write('Pause'); end;
  if i=50 then begin gotoxy(27,4); write('     '); end;
  i:=(i+1) mod 100;
 until keypressed;
 if lo(nextkey)=0 then c:=readkey;  c:=readkey;
 squeak(unp); gotoxy(27,4); write('      ');
end;

{ game over }
procedure lose;
var
i,n: byte; d:word; c:char;
begin;
 if (hx > maxx -1) or (hy>maxy) or (hx<0) or (hy<0) then begin dx:=0; dy:=0; end;
 if hx > maxx-1 then hx:=maxx-1; if hy > maxy then hy:=maxy;
 if hx < 0 then hx:=0; if hy <0 then hy:=0;
 bx:=hx+hx+hx; by:=hy+hy+hy;
 gotoxy(27,4); write('Oh no!');
 dh; display; { draw final head placement }
 squeak(die);
 while keypressed do c:=readkey; { clear out kbd buffer }
 for i:=1 to 6 do begin { flash head }
  if odd(i) then n:=0 else n:=1;
  d:=1000 + word(n) shl 9; delay(d);
  plot(bx,by,n); plot(bx+1,by,n); plot(bx,by+1,n); plot(bx+1,by+1,n); display;
 end;
 waitkey; clrscr;
end;
{ generate an item of food on free space }
procedure makefood;
begin
 repeat
  fx:=random(maxx); fy:=random(maxy);
  bx:=fx+fx+fx; by:=fy+fy+fy;
 until point(bx,by)=0;
 plot(bx,by,1); plot(bx+1,by+1,1);
 { only diagonal dots for end of level portal }
 if f>1 then begin plot(bx,by+1,1); plot(bx+1,by,1); end;
 display;
end;
{ initialise variables }
procedure init; 
begin;
 clrscr; col:=false;
 line(maxx*3,0,maxx*3,31,1); display;
 f:=0; lv:=0; grow:=ilen-1; len:=1;
 hcap:=ihcap; dly:=idly; dc:=1;
 hx:=20; hy:=5; tx:=hx; ty:=hy;
 dx:=0; dy:=0;
 dh; display; dx:=1;
 lvup; randomize; makefood;
end;
procedure introstep(won:boolean);
begin
 gotoxy(5,4);
 if (hx=6)  and (hy=1) then begin dc:=dly-1; dx:=1; dy:=0;  if won then write(' -= SPACEW0RM =- ') else write('ARROWS      :MOVE'); end;
 if (hx=43) and (hy=1) then begin dc:=dly-1; dx:=0; dy:=1;  if won then write('     (c) 2021    ') else write('+           :FAST'); end;
 if (hx=43) and (hy=6) then begin dc:=dly-1; dx:=-1; dy:=0; if won then write('Wojciech Owczarek') else write('BRK         :EXIT'); end;
 if (hx=6)  and (hy=6) then begin dc:=dly-1; dx:=0; dy:=-1; if won then write('DL-PASCAL PB-2000') else write('P,BS        :PAUS'); end;
end;
{you won}
procedure win;
var c:char; n:integer;
snd:array[0..23] of integer=(400,10,10,400,400,400,400,10,10,400,400,400,400,10,10,400,400,400,300,10,300,10,300,10);
begin
 clrscr; n:=0;
 score(pts);
 gotoxy(5,2); write('Y 0 U   W I N ! ! ');
 hx:=5; hy:=1; tx:=hx;ty:=hy; dx:=0; dy:=0; grow:=10; dh; dx:=1; idly:=20; dc:=0; dly:=idly; display;
 repeat
  if dc=0 then begin
   hx:=hx+dx; hy:=hy+dy;
   if grow = 0 then dly:=idly else dly:=idly+6;
   sound(snd[n],40); n:=(n+1) mod 24;
   if grow = 0 then et else dec(grow);
   dh; display;
  end;
  if dc = 1 then introstep(true);
  if keypressed then case readkey of
   #0:  {2-code} c:=readkey;
   #3:  {brk}    begin; clrscr; exit; end;
  end;
  dc:=(dc+1) mod dly;
 until false;
end;
{ the intro! }
procedure intro;
var c:char; n:integer;
snd: array[0..7]  of integer=(200,200,240,200,240,200,236,220);
begin
 clrscr; n:=0;
 gotoxy(25,1); write('1:INFANT'); gotoxy(25,2); write('2:NORMIE');
 gotoxy(25,3); write('3:EXPERT'); gotoxy(25,4); write('4:HD6170');
 gotoxy(5,2); write('S P A C E W 0 R M');
 hx:=5; hy:=1; tx:=hx;ty:=hy; dx:=0; dy:=0; grow:=10; dh; dx:=1; idly:=10; dly:=idly; dc:=0; display;
 repeat
  if dc=0 then begin
   hx:=hx+dx; hy:=hy+dy;
   if grow = 0 then dly:=idly else dly:=idly+6;
   if n<16 then sound(round(snd[n mod 8]*1.0),40) else sound(round(snd[n mod 8]*1.3), 40); n:=(n+1) mod 32;
   if grow = 0 then et else dec(grow);
   dh; display;
  end;
  if dc = 1 then introstep(false);
  if keypressed then case readkey of
   #0:  {2-code} c:=readkey;
   #3:  {brk}    begin; clrscr; halt; end;
   #49: {1}      begin; lbn:=0; idly:=100; ihcap:=50; dlystep:=40; exit; end;
   #50: {2}      begin; lbn:=1; idly:=60;  ihcap:=40; dlystep:=20; exit; end;
   #51: {3}      begin; lbn:=3; idly:=30;  ihcap:=20; dlystep:=10; exit; end;
   #52: {4}      begin; lbn:=5; idly:=20;  ihcap:=10; dlystep:=5;  exit; end;
  end;
  dc:=(dc+1) mod dly;
 until false;
end;
{ main }
label endloop;
begin
dispstatus:=2; 
intro; init; score(0); squeak(lup);
repeat
 repeat
  if dc = 0 then begin { only move every n loops }
   chd:=1; { max 1 direction changes per move }
   hx:=hx+dx; hy:=hy+dy;
   if grow=0 then et else begin dec(grow); inc(len); end; { advance tail }
   { collision detection }
   col := (point(hx+hx+hx,hy+hy+hy)=1) or (hx<0) or (hy<0) or (hx>maxx) or (hy>maxy);
   if (hx=fx) and (hy=fy) then begin { found food }
    col:=false; dec(f); score(pts+1+lbn+len div 10); { extra point per 10 length }
    if f=0 then begin squeak(lup);
      if lv=10 then begin win; intro; init; score(0); goto endloop; end else begin lvup; dc:=1; grow:=ilen-blen; end;
    end { end of level, or win }
    { no escaping fp here, we need ceil to fit the curve }
    else begin squeak(eat); inc(gacc, round(ceil(gacc *0.2)) + lv); inc(grow,gacc-gacc1); gacc1:=gacc; end;
    gotoxy(27, 3); write('obj:',f-1); if f < 11  then write(' ');
    makefood; { make more food }
   end;
   if not col then dh; { head can be drawn differently on collision }
   display;
  end;
  dc:=(dc+1) mod dly; { increment delay counter, cycle 0..dly }
  if col then begin lose; init; score(0); end; { game over }
 until keypressed;
 case readkey of
  #0: if chd>0 then case readkey of
     #77: {r} if dx=0 then begin dx:=1;  dy:=0;  dc:=0; dec(chd); end;
     #75: {l} if dx=0 then begin dx:=-1; dy:=0;  dc:=0; dec(chd); end;
     #72: {u} if dy=0 then begin dx:=0;  dy:=-1; dc:=0; dec(chd); end;
     #80: {d} if dy=0 then begin dx:=0;  dy:=1;  dc:=0; dec(chd); end;
  end;
  #3:  {brk} begin; intro; init; score(0); squeak(lup);end;
  #8,#80,#112: {bs,p,P} pause;
  #12: {cls} begin lv:=0; init; score(0); end;
  #43: {+}   if dly>0 then begin; dec(dly,5); dc:=1; end;
 end;
 endloop:
 until false;
end.
