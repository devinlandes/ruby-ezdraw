require 'ezdraw'
 
include EZDraw::DSL

init([200,200])

stroke(Red)
fill(Green)
circle(width/2, height/2, width/3)

stroke(Black)
text(0,0,"hello world")
waitkey

cleanup

