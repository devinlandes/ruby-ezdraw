require_relative 'sdl2'
require 'logger'

module EZDraw
 White = [0xff, 0xff, 0xff, 0xff].freeze
 Black = [0x00, 0x00, 0x00, 0xff].freeze
 Gray  = [0x88, 0x88, 0x88, 0xff].freeze

 Red   = [0xff, 0x00, 0x00, 0xff].freeze
 Green = [0x00, 0xff, 0x00, 0xff].freeze
 Blue  = [0x00, 0x00, 0xff, 0xff].freeze

 Yellow  = [0xff, 0xff, 0x00, 0xff].freeze
 Magenta = [0xff, 0x00, 0xff, 0xff].freeze
 Cyan    = [0x00, 0xff, 0xff, 0xff].freeze

 Brown   = [0xa5, 0x2a, 0x2a, 0xff].freeze

 None  = [0x00, 0x00, 0x00, 0x00].freeze

 @@logger = Logger.new(STDERR)
 @@logger.level = Logger::WARN
 @@logger.progname = "EZDraw"
 def self.logger
  @@logger
 end

 # auto-handles path sep
 def self.gem_relative_path(path)
  gem_root = File.expand_path('..', File.dirname(__FILE__))
  path = File.join(*(path.split("/")))
  File.join(gem_root, path)
 end
 private_class_method :gem_relative_path

 @@inited = false

 def self.init
  return if inited

  if SDL2.SDL_WasInit(SDL2::SDL_INIT_VIDEO) == 0
   err = SDL2.SDL_Init(SDL2::SDL_INIT_VIDEO)
   raise "SDL_Init: ${SDL2.SDL_GetError}" if err != 0
  end

  Image.init
  Font.init

  @@inited = true

  # TODO: set font size more dynamically?
  @@default_font = EZDraw::Font.new(gem_relative_path("res/AnonymousPro-Regular.ttf"), 20)
  nil
 end

 def self.default_font
  requires_init
  @@default_font
 end

 def self.inited
  @@inited == true
 end

 def self.requires_init
  raise "EZDraw is not initialized. first call EZDraw.init" if not inited
 end

 def self.cleanup
  requires_init
  Font.cleanup
  Image.cleanup
  Window.cleanup
  SDL2.SDL_Quit
  @@inited = false
  nil
 end

 def self.delay(msec)
  requires_init
  SDL2.SDL_Delay(msec)
  nil
 end

 # this version eats all events while waiting for a key
 #def self.waitkey_gluttonous
  #loop do
   #ev_p = FFI::MemoryPointer.new SDL2::SDL_Event, 1, false
   #ev = SDL2::SDL_Event.new ev_p
   #SDL2.SDL_WaitEvent(ev_p)
   #break if ev[:type] == SDL2::SDL_KEYDOWN
  #end
 #end

 # this version cherry-picks keyboard events from the queue
 def self.waitkey
  requires_init
  ev_p = FFI::MemoryPointer.new SDL2::SDL_Event, 1, false
  ev = SDL2::SDL_Event.new ev_p
  #cev = SDL2::SDL_CommonEvent.new ev_p

  loop do
   nev = SDL2.SDL_PeepEvents(ev_p, 1, SDL2::SDL_GETEVENT, SDL2::SDL_KEYDOWN, SDL2::SDL_KEYUP)

   raise "error: peepevents" if nev < 0
   if nev == 0
    SDL2.SDL_PumpEvents
    delay 1
    next
   end

   #EZDraw.logger.debug("0x#{ev[:common][:type].to_s(16)}")
   if ev[:common][:type] == SDL2::SDL_KEYDOWN
    return SDL2.SDL_GetKeyName(ev[:key][:keysym][:keycode]).to_s
   end
  end
 end

 class Window
  @@instances = []

  def initialize(size=:default, title=:default, *opts)
   EZDraw.requires_init

   if size == :default
    # TODO: use SDL's GetCurrentDisplayMode and make default proportional (30% ?) the size of screen
    w = h = 500
   else
    w, h = size
   end

   if title == :default
    title = $PROGRAM_NAME
   end

   # TODO: couldn't find an elegant way to put this option in the interface
   # perhaps kv args? but then how to pass fullscreen?
   x = y = SDL2::SDL_WINDOWPOS_UNDEFINED

   wflags = 0
   wflags |= SDL2::SDL_WINDOW_FULLSCREEN if opts.include? :fullscreen

   @win = SDL2.SDL_CreateWindow(title, x, y, w, h, wflags)

   # TODO: add renderer options to interface
   # eg. :software, :accelerated, :vsync
   @ren = SDL2.SDL_CreateRenderer(@win, -1, SDL2::SDL_RENDERER_ACCELERATED | SDL2::SDL_RENDERER_TARGETTEXTURE)

   sz = get_window_size
   rinfo = get_renderer_info
   @buf = SDL2::SDL_CreateTexture(@ren, rinfo[:texture_formats][0],
                                  SDL2::SDL_TEXTUREACCESS_TARGET, sz[0], sz[1])
   SDL2.SDL_SetRenderTarget(@ren, @buf)

   @fill = White
   @stroke = Black
   @font = EZDraw::default_font
   @dc_stack = []

   self.render_draw_color = fill
   SDL2.SDL_RenderClear(@ren)

   auto_update(true)

   # finalizer
   @dflag = [false]
   ObjectSpace.define_finalizer(self, proc {|id|
    self.class._destroy(@win, @ren, @buf, @dflag)
   })
   @@instances << self
  end

  def self._destroy(win, ren, buf, dflag)
   if dflag[0]
    #EZDraw.logger.debug("(already destroyed window #{win})")
    return
   end
   EZDraw.logger.debug("destroy window #{win}")

   SDL2.SDL_DestroyTexture(buf)
   SDL2.SDL_DestroyRenderer(ren)
   SDL2.SDL_DestroyWindow(win)
   dflag[0] = true
  end

  def close
   self.class._destroy(@win, @ren, @buf, @dflag)
  end 

  def self.cleanup
   EZDraw.requires_init
   @@instances.each {|win| win.close}
   @@instances = []
  end

  # NOTE: these accessors are to circumvent the method/local-variable ambiguity
  # that results with "stroke = color", and thus needs to be "self.stroke = color"
  # however...
  def stroke(color=nil)
   color ? @stroke=color : @stroke
  end

  def fill(color=nil)
   color ? @fill=color : @fill
  end

  def font(fnt=nil)
   fnt ? @font=fnt : @font
  end

  # ...however, traditional foo= writers are also provided
  attr_writer :fill, :stroke, :font

  def push_context
   @dc_stack.push([@stroke.clone, @fill.clone, @font, @auto_update])
  end

  def pop_context
   raise "dc stack empty" if @dc_stack.length == 0
   @stroke, @fill, @font, auto_up = @dc_stack.pop
   auto_update(auto_up)
  end

  def get_window_size
   p_w = FFI::MemoryPointer.new :int
   p_h = FFI::MemoryPointer.new :int
   SDL2.SDL_GetWindowSize(@win, p_w, p_h)
   [p_w.get_int(0), p_h.get_int(0)]
  end

  def width
   get_window_size[0]
  end

  def height
   get_window_size[1]
  end

  def get_renderer_info
   p_rinfo = FFI::MemoryPointer.new :uint8, SDL2::SDL_RendererInfo.size, false
   SDL2::SDL_GetRendererInfo(@ren, p_rinfo)
   rinfo = SDL2::SDL_RendererInfo.new p_rinfo
  end
  private :get_renderer_info

  def render_draw_color
   pr = FFI::MemoryPointer.new :uint8
   pg = FFI::MemoryPointer.new :uint8
   pb = FFI::MemoryPointer.new :uint8
   pa = FFI::MemoryPointer.new :uint8
   SDL2::SDL_GetRenderDrawColor(@ren, pr, pg, pb, pa)
   [pr.get_uint8(0), pg.get_uint8(0), pb.get_uint8(0), pa.get_uint8(0)]
  end
  private :render_draw_color

  def render_draw_color=(rgba)
   SDL2::SDL_SetRenderDrawColor(@ren, rgba[0], rgba[1], rgba[2], rgba[3])
  end
  private :render_draw_color=

  def clear
   self.render_draw_color = fill
   SDL2.SDL_RenderClear(@ren)
   need_update
  end

  def line(x0, y0, x1, y1)
   SDL2::Gfx.lineRGBA(@ren, x0, y0, x1, y1, stroke[0], stroke[1], stroke[2], stroke[3])
   need_update
  end

  def rect(x0, y0, x1, y1)
   SDL2::Gfx.boxRGBA(@ren, x0, y0, x1, y1, fill[0], fill[1], fill[2], fill[3])
   SDL2::Gfx.rectangleRGBA(@ren, x0, y0, x1, y1, stroke[0], stroke[1], stroke[2], stroke[3])
  end

  def circle(x, y, r)
   SDL2::Gfx.filledCircleRGBA(@ren, x, y, r, fill[0], fill[1], fill[2], fill[3])
   SDL2::Gfx.circleRGBA(@ren, x, y, r, stroke[0], stroke[1], stroke[2], stroke[3])
   need_update
  end

  # x,y => draw location (or...)
  # x,y => src_rect, dst_rect arrays
  def text(x, y, text)
   sfc = @font.render(text, stroke)
   tex = SDL2.SDL_CreateTextureFromSurface(@ren, sfc)

   w_p = FFI::MemoryPointer.new :int, 1, false
   h_p = FFI::MemoryPointer.new :int, 1, false
   err = SDL2.SDL_QueryTexture(tex, nil, nil, w_p, h_p)
   raise "SDL_QueryTexture: #{SDL2::SDL_GetError}" if err != 0

   r = SDL2::SDL_Rect.new
   r[:x] = x
   r[:y] = y
   r[:w] = w_p.get_int(0)
   r[:h] = h_p.get_int(0)
   SDL2.SDL_RenderCopy(@ren, tex, nil, r)
   need_update
  end

  def self.parse_rect(r)
  end

  def image(x, y, img)

   if img.is_a? String
    img = Image.new(img)
   end

   sfc = img.instance_exec {self.sfc}

   tex = SDL2.SDL_CreateTextureFromSurface(@ren, sfc)
   #w_p = FFI::MemoryPointer.new :int, 1, false
   #h_p = FFI::MemoryPointer.new :int, 1, false
   #err = SDL2.SDL_QueryTexture(tex, nil, nil, w_p, h_p)
   #raise "SDL_QueryTexture: #{SDL2::SDL_GetError}" if err != 0
   #img_w, img_h = w_p.get_int(0), h_p.get_int(0)

   src_r = dst_r = nil 
 
   if x.is_a? Numeric
    dst_r = SDL2::SDL_Rect.new
    dst_r[:x], dst_r[:y], dst_r[:w], dst_r[:h] = x, y, img.width, img.height
   else
    if x.is_a? Array
     src_r = SDL2::SDL_Rect.new
     src_r[:x], src_r[:y], src_r[:w], src_r[:h] = x[0], x[1], img.width, img.height
     src_r[:w], src_r[:h] = x[2], x[3] if x.length == 4
    end

    if y.is_a? Array
     dst_r = SDL2::SDL_Rect.new
     dst_r[:x], dst_r[:y], dst_r[:w], dst_r[:h] = y[0], y[1], img.width, img.height
     dst_r[:w], dst_r[:h] = y[2], y[3] if y.length == 4
    end 
  end

   SDL2.SDL_RenderCopy(@ren, tex, src_r, dst_r)

   # BUG: cleanup after exception
   SDL2.SDL_DestroyTexture(tex)
   need_update
  end

  def auto_update?
   @auto_update
  end

  def auto_update(enable_p)
   # force an update if enabling auto
   update if enable_p and not @auto_update

   @auto_update = enable_p
  end

  def auto_update=(enable_p)
   auto_update(enable_p)
  end

  # draw all simultaneously and update at the end
  # BUG: should nest but doesn't
  # BUG: if the block meddles with auto_update, the contract fails
  # perhaps an auto_update override-lock mechanism to fix this?
  def draw(&block)
   auto_update(false)
   block.call
   auto_update(true)
  end

  def need_update
   @need_update = true
   update if auto_update?
  end

  def update
   return if not @need_update
   SDL2.SDL_SetRenderTarget(@ren, nil)
   SDL2.SDL_RenderCopy(@ren, @buf, nil, nil)
   SDL2.SDL_RenderPresent(@ren)
   SDL2.SDL_SetRenderTarget(@ren, @buf)
   @need_update = false
  end

 end

 class Image
  @@instances = []

  def initialize(img_filename)
   EZDraw.requires_init
 
   @sfc = SDL2::Image.IMG_Load(img_filename)
   raise "IMG_Load: #{SDL2::Image.IMG_GetError}" if @sfc.null?

   @dflag = [false] #shared-changable
   ObjectSpace.define_finalizer(self, proc {|id|
    self.class._destroy(@sfc, @dflag)
   })
   
   @@instances << self
  end

  attr_reader :sfc

  def self.init
   iflags = SDL2::Image::IMG_INIT_JPG |
	    SDL2::Image::IMG_INIT_PNG |
	    SDL2::Image::IMG_INIT_TIF
   oflags = SDL2::Image.IMG_Init(iflags)
   raise "IMG_Init: #{SDL2::Image.IMG_GetError}" if (oflags & iflags) != iflags
  end

  def self.cleanup
   EZDraw.requires_init
   @@instances.each {|img| img.close}
   @@instances = []
   SDL2::Image.IMG_Quit
  end

  def self._destroy(sfc, dflag)
   if dflag[0]
    #EZDraw.logger.debug "(already destroyed image #{sfc})"
    return
   end
   EZDraw.logger.debug "destroy image #{sfc}"

   SDL2.SDL_FreeSurface(sfc)
   dflag[0] = true
  end

  def close
   self.class._destroy(@sfc, @dflag)
  end

  def width
   @sfc[:w]
  end

  def height
   @sfc[:h]
  end
 end

 class Font
  @@instances = []

  # TODO: better API to distinguish between unsized "typeface" and sized "font"?
  def initialize(ttf_filename, ptheight)
   EZDraw.requires_init

   @font = SDL2::Ttf.TTF_OpenFont(ttf_filename, ptheight)
   raise "TTF_OpenFont: #{SDL2::Ttf.TTF_GetError}" if @font.null? 

   # wrapping in array to make changes shared by all references
   @destroyed_flag = [false]
   ObjectSpace.define_finalizer(self, proc {|id|
    self.class.class._destroy(@font, @destroyed_flag)
   })

   @@instances << self
  end

  def self.init
   if SDL2::Ttf.TTF_WasInit == 0
    err = SDL2::Ttf.TTF_Init
    raise "TTF_Init: #{SDL2::Ttf.TTF_GetError}" if err != 0
   end
  end

  def self.cleanup
   EZDraw.requires_init

   # destroy instances explicitly
   # to prevent finalizers from double-destroying after TTF_Quit
   @@instances.each {|font| font.close}
   @@instances = []
   SDL2::Ttf.TTF_Quit
  end

  def self._destroy(font, destroyed_flag)
   if destroyed_flag[0]
    #EZDraw.logger.debug "(already destroyed font #{font})"
    return
   end

   EZDraw.logger.debug "destroy font #{font}"
   SDL2::Ttf.TTF_CloseFont(font)
   destroyed_flag[0] = true
  end

  def close
   self.class._destroy(@font, @destroyed_flag)
  end

  def height
   # BUG: methods should check whether font was destroyed
   SDL2::Ttf.TTF_FontHeight(@font)
  end

  def line_pitch
   SDL2::Ttf.TTF_FontLineSkip(@font)
  end


  attr_reader :font

  def render_utf8(text, color)
   c = SDL2::SDL_Color.new 
   c[:r] = color[0]
   c[:g] = color[1]
   c[:b] = color[2]
   c[:a] = color[3]
   sfc = SDL2::Ttf.TTF_RenderUTF8_Solid(@font, text, c)
  end

  alias render render_utf8
 end

 module DSL
  # BUG: this should be per-including-instance
  @@win = nil

  def self.included(base)
   EZDraw.constants.each {|c|
    EZDraw.logger.debug("#{base}.const_set #{c}")
    base.const_set c, EZDraw.const_get(c)
   }
  end

  def init(*opts)
   EZDraw.init
   @@win = EZDraw::Window.new(*opts)
  end

  def cleanup
   EZDraw.requires_init
   @@win = nil
   EZDraw.cleanup
  end

  def method_missing(name, *args, &block)
   delegates = [EZDraw, @@win]
   delg = delegates.find {|delg_i| delg_i.respond_to?(name)}
   delg ? delg.public_send(name, *args, &block) : super
  end

  def const_missing(name)
   raise "const #{name}"
  end

 end

end
