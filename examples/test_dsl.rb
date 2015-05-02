require 'ezdraw'

include EZDraw::DSL

SCRIPT_DIR = File.dirname(__FILE__)

init

draw {
stroke(Blue)
(0..width).step(20) {|x| line(x,0,width-x,height) }
(0..height).step(20) {|y| line(0,y,width,height-y) }
}
delay(100)

draw {
 stroke(Red)
 (0..width).step(20) {|x| line(x,0,width-x,height) }
 (0..height).step(20) {|y| line(0,y,width,height-y) }
}
delay(100)

img = Image.new("#{SCRIPT_DIR}/res/star.png")
image(0,0, img)
delay(100)
image([0,0,img.width/2,img.height/2], nil, img)
delay(100)
image(nil, [0,0,width,height], img)

draw {
stroke(Brown)
fill(Yellow)
circle(width/2,height/2,width/5)
}

waitkey

cleanup

