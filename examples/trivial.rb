require 'ezdraw'
 
include EZDraw::DSL

init

stroke(Red)
fill(Green)
text(0,0,"hello world")
circle(width/2, height/2, width/3)

waitkey
cleanup

