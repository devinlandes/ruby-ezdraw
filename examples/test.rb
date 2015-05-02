require 'ezdraw'

#EZDraw.logger.level = Logger::DEBUG

SCRIPT_DIR = File.dirname(__FILE__)

EZDraw.init

win = EZDraw::Window.new(:default, "awesome test window")

win.auto_update = false
img = EZDraw::Image.new("#{SCRIPT_DIR}/res/star.png")
y = 0
while y < win.height
 x = 0
 while x < win.height
  win.image(x, y, img)
  x += img.width
 end
 y += img.height
end
win.auto_update = true
win.image(win.width/2, win.height/2, "#{SCRIPT_DIR}/res/star.png")

win.stroke = EZDraw::Blue
win.fill = EZDraw::Gray
win.line(0,0,win.width,win.height)
win.circle(win.width/2, win.height/2, win.width/3)
win.rect(10,10,50,50)

win.push_context
win.stroke = EZDraw::Red
win.fill = EZDraw::None
win.circle(100,100,50)
win.pop_context

win.stroke = EZDraw::Green
win.line(0,0,win.width/2,win.height)
win.circle(200,100,50)
win.line(0,0,win.width,win.height/2)
win.stroke = EZDraw::Black
win.push_context
win.text(0,0,"hello world")
win.font = EZDraw::Font.new("#{SCRIPT_DIR}/res/opensans.ttf", 80)
win.stroke = EZDraw::Green
win.text(0, 20, "hello world")
win.pop_context
win.text(0,100,"hello world")

def rnd n
 Random.rand(n)
end

100.times {
 win.stroke = [rnd(0xff),rnd(0xff),rnd(0xff),0xff]
 win.line(rnd(win.width),rnd(win.height),rnd(win.width),rnd(win.height))
}
win.auto_update = false
100.times {
 win.stroke = [rnd(0xff),rnd(0xff),rnd(0xff),0xff]
 win.line(rnd(win.width),rnd(win.height),rnd(win.width),rnd(win.height))
}
win.auto_update = true
EZDraw.waitkey

EZDraw.cleanup

