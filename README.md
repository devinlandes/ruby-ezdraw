# ruby-ezdraw
A fun little drawing API for Ruby (using SDL2+FFI)

# features
- simple Processing-esq API
- automatic canvas updating (optional)
- lines, circles, rects
- ttf fonts (with a default font included)
- images (png, jpg, etc via SDL_image)

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
