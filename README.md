# ruby-ezdraw
A fun little drawing API for Ruby (using SDL2+FFI)

# features
- simple Processing-esq API
- automatic canvas updating (optional)
- lines, circles, rects
- ttf fonts (with a default font included)
- images (png, jpg, etc via SDL_image)
- resources are garbage-collected

# example
    require 'ezdraw'
    
    include EZDraw::DSL
    
    init
    
    stroke(Red)
    fill(Green)
    text(0,0,"hello world")
    circle(width/2, height/2, width/3)
    
    waitkey
    cleanup

# quick manual

    # inject ezdraw's methods and consts into self/main
    include EZDraw::DSL
    init(*window_options_if_desired)
    line(0,0,width,height)
    waitkey
    cleanup

    # or access the API through a window object (multiple windows supported)
    EZDraw.init
    win = EZDraw::Window.new
    win.line(0,0,win.width,win.height)
    EZDraw.cleanup

    init, cleanup                # wrap all other commands with these

    Window.new                   # default size and title
    Window.new([w,h],title)      # or specify
    Window.new(..., :fullscreen) # fullscreen!

    # colors are [r,g,b,a] (0-255)
    stroke(color), fill(color)   # set stroke and fill colors

    line(x1,y1,x2,y2)
    circle(x,y,r)
    rect(x1,y1,x2,y2)

    width,height  # size of the canvas

    # optionally disable auto-updating
    # which allows commands to be drawn more quickly
    # and appear all at once
    auto_update(bool), auto_update?, update
    
    # or put a set of commands in a draw block to get the same effect
    draw {
     (0..width).each {|x| line(x,0,x,height)}
    }

    text(x,y,str)             # draw text (a default font is provided)
    font(Font.new(filename))  # change the font

    img = Image.new(filename)  # load an image from disk
    image(x,y,img)
    img.width, img.height      # images know their size

    image(x,y,filename)       # draw an image directly from a file!

    # image sub-sections and scaling
    # points are [x,y]. rects are [x,y,w,h]
    image(src_pt_or_rect, dst_pt_or_rect, img)
