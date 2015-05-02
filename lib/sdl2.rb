require 'ffi'

module SDL2
 module EnumUtil
  # enum_consts
  # convenient like FFI's enum
  # but creates the symbols as normal consts
  # which I believe is more natural to ruby

  def enum_consts *args
   pname = nil
   value = 1

   args.each do |arg|

    if arg.is_a? Symbol
     if pname
      #puts "const_set #{pname} = #{value}"
      const_set(pname, value)
      pname = nil
      value += 1
     end
     pname = arg
  
    elsif arg.is_a? Integer
     if pname
      value = arg
      #puts "const_set #{pname} = #{value}"
      const_set(pname, value)
      pname = nil
      value += 1
     else
      raise "unexpected integer without preceeding name"
     end
    end

   end # do

   if pname
    #puts "const_set #{pname} = #{value}"
    const_set(pname, value)
   end

  end
 end
end

module SDL2
 extend FFI::Library
 ffi_lib "libSDL2"

 extend SDL2::EnumUtil

 ## INIT
 attach_function :SDL_Init, [:uint32], :int
 attach_function :SDL_Quit, [], :void
 attach_function :SDL_WasInit, [:uint32], :uint32

 attach_function :SDL_GetError, [], :string

 SDL_INIT_TIMER          = 0x00000001
 SDL_INIT_AUDIO          = 0x00000010
 SDL_INIT_VIDEO          = 0x00000020  # SDL_INIT_VIDEO implies SDL_INIT_EVENTS
 SDL_INIT_JOYSTICK       = 0x00000200  # SDL_INIT_JOYSTICK implies SDL_INIT_EVENTS
 SDL_INIT_HAPTIC         = 0x00001000
 SDL_INIT_GAMECONTROLLER = 0x00002000  # SDL_INIT_GAMECONTROLLER implies SDL_INIT_JOYSTICK
 SDL_INIT_EVENTS         = 0x00004000
 SDL_INIT_NOPARACHUTE    = 0x00100000  # Don't catch fatal signals
 SDL_INIT_EVERYTHING     =  SDL_INIT_TIMER | SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_EVENTS | \
                            SDL_INIT_JOYSTICK | SDL_INIT_HAPTIC | SDL_INIT_GAMECONTROLLER

 
 # UTIL
 attach_function :SDL_Delay, [:uint32], :void


 # EVENT

 class SDL_CommonEvent < FFI::Struct
  layout \
   :type, :uint32,
   :timestame, :uint32
  end

 class SDL_Keysym < FFI::Struct
  layout \
   :scancode, :int, #enum
   :keycode, :int, #enum
   :mode, :uint16,
   :unused, :uint32
 end

 # could all event structs inherit from CommonEvent?
 class SDL_KeyboardEvent < FFI::Struct
  layout \
   :type, :uint32,
   :timestamp, :uint32,
   :windowID, :uint32,
   :state, :uint8,
   :repeat, :uint8,
   :keysym, SDL_Keysym
 end

 class SDL_Event < FFI::Union
  layout \
   :common, SDL_CommonEvent,
   # SDL_CommonEvent common;         /**< Common event data */
   # SDL_WindowEvent window;         /**< Window event data */
   :key, SDL_KeyboardEvent,
   # SDL_TextEditingEvent edit;      /**< Text editing event data */
   # SDL_TextInputEvent text;        /**< Text input event data */
   # SDL_MouseMotionEvent motion;    /**< Mouse motion event data */
   # SDL_MouseButtonEvent button;    /**< Mouse button event data */
    #SDL_MouseWheelEvent wheel;      /**< Mouse wheel event data */
    #SDL_JoyAxisEvent jaxis;         /**< Joystick axis event data */
    #SDL_JoyBallEvent jball;         /**< Joystick ball event data */
    #SDL_JoyHatEvent jhat;           /**< Joystick hat event data */
    #SDL_JoyButtonEvent jbutton;     /**< Joystick button event data */
    #SDL_JoyDeviceEvent jdevice;     /**< Joystick device change event data */
    #SDL_ControllerAxisEvent caxis;      /**< Game Controller axis event data */
    #SDL_ControllerButtonEvent cbutton;  /**< Game Controller button event data */
    #SDL_ControllerDeviceEvent cdevice;  /**< Game Controller device event data */
    #SDL_QuitEvent quit;             /**< Quit request event data */
    #SDL_UserEvent user;             /**< Custom event data */
    #SDL_SysWMEvent syswm;           /**< System dependent window event data */
    #SDL_TouchFingerEvent tfinger;   /**< Touch finger event data */
    #SDL_MultiGestureEvent mgesture; /**< Gesture event data */
    #SDL_DollarGestureEvent dgesture; /**< Gesture event data */
    #SDL_DropEvent drop;             /**< Drag and drop event data */

   :padding, [:uint8, 56]
 end

 typedef :pointer, :SDL_Event_out
 typedef :int, :SDL_eventaction
 attach_function :SDL_PeepEvents, [:SDL_Event_out, :int, :SDL_eventaction, :uint32, :uint32], :int
 attach_function :SDL_PollEvent, [:SDL_Event_out], :int
 attach_function :SDL_WaitEvent, [:SDL_Event_out], :int
 attach_function :SDL_PumpEvents, [], :void

 #### enum SDL_EventType

 enum_consts \
  :SDL_FIRSTEVENT,     0,    # Unused (do not remove)

 # Application events
  :SDL_QUIT,           0x100, # User-requested quit

 # These application events have special meaning on iOS, see README-ios.txt for details
  :SDL_APP_TERMINATING,         0x101, # The application is being terminated by the OS
  :SDL_APP_LOWMEMORY,                  # The application is low on memory, free memory if possible.
  :SDL_APP_WILLENTERBACKGROUND,        # The application is about to enter the background
  :SDL_APP_DIDENTERBACKGROUND,         # The application did enter the background and may not get CPU for some time
  :SDL_APP_WILLENTERFOREGROUND,        # The application is about to enter the foreground
  :SDL_APP_DIDENTERFOREGROUND,         # The application is now interactive

 # Window events
  :SDL_WINDOWEVENT, 0x200, # Window state change
  :SDL_SYSWMEVENT,         # System specific event

 # Keyboard events
  :SDL_KEYDOWN,     0x300, # Key pressed
  :SDL_KEYUP,              # Key released
  :SDL_TEXTEDITING,        # Keyboard text editing (composition)
  :SDL_TEXTINPUT,          # Keyboard text input

 # Mouse events
  :SDL_MOUSEMOTION,  0x400, # Mouse moved
  :SDL_MOUSEBUTTONDOWN,     # Mouse button pressed
  :SDL_MOUSEBUTTONUP,       # Mouse button released
  :SDL_MOUSEWHEEL,          # Mouse wheel motion

 # Joystick events
  :SDL_JOYAXISMOTION,   0x600, # Joystick axis motion
  :SDL_JOYBALLMOTION,          # Joystick trackball motion
  :SDL_JOYHATMOTION,           # Joystick hat position change
  :SDL_JOYBUTTONDOWN,          # Joystick button pressed
  :SDL_JOYBUTTONUP,            # Joystick button released
  :SDL_JOYDEVICEADDED,         # A new joystick has been inserted into the system
  :SDL_JOYDEVICEREMOVED,       # An opened joystick has been removed

 # Game controller events
  :SDL_CONTROLLERAXISMOTION,   0x650, # Game controller axis motion
  :SDL_CONTROLLERBUTTONDOWN,          # Game controller button pressed
  :SDL_CONTROLLERBUTTONUP,            # Game controller button released
  :SDL_CONTROLLERDEVICEADDED,         # A new Game controller has been inserted into the system
  :SDL_CONTROLLERDEVICEREMOVED,       # An opened Game controller has been removed
  :SDL_CONTROLLERDEVICEREMAPPED,      # The controller mapping was updated

 # Touch events
  :SDL_FINGERDOWN,            0x700,
  :SDL_FINGERUP,
  :SDL_FINGERMOTION,

  :SDL_DOLLARGESTURE,         0x800,
  :SDL_DOLLARRECORD,
  :SDL_MULTIGESTURE,

  :SDL_CLIPBOARDUPDATE,       0x900, # The clipboard changed
  :SDL_DROPFILE,              0x1000, # The system requests a file open
  :SDL_RENDER_TARGETS_RESET,  0x2000, # The render targets have been reset

  :SDL_USEREVENT,   0x8000,
  :SDL_LASTEVENT,   0xFFFF
 
 #### enum SDL_eventaction
 enum_consts \
  :SDL_ADDEVENT,    0,
  :SDL_PEEKEVENT,
  :SDL_GETEVENT

 # KEYBOARD
 typedef :int, :SDL_Keycode
 attach_function :SDL_GetKeyName, [:SDL_Keycode], :string

 # VIDEO
 typedef :pointer, :SDL_Window
 typedef :pointer, :SDL_Window_out
 typedef :pointer, :SDL_Renderer
 typedef :pointer, :SDL_Renderer_out
 typedef :pointer, :SDL_Surface
 typedef :pointer, :SDL_Texture
 typedef :pointer, :SDL_RendererInfo_out
 typedef :pointer, :uint32_out
 typedef :pointer, :uint8_out
 typedef :pointer, :int_out

 class SDL_RendererInfo < FFI::Struct
  layout :name, :string,
         :flags, :uint32,
         :num_texture_formats, :uint32,
         :texture_formats, [:uint32, 16],
         :max_texture_width, :int,
         :max_texture_height, :int
 end

 class SDL_Color < FFI::Struct
  layout \
   :r, :uint8,
   :g, :uint8,
   :b, :uint8,
   :a, :uint8
 end

 class SDL_Rect < FFI::Struct
  layout \
   :x, :int,
   :y, :int,
   :w, :uint,
   :h, :uint
 end

 class SDL_Surface < FFI::Struct
  layout \
   :flags, :uint32,
   :format, :pointer,
   :w, :int,
   :h, :int,
   :pitch, :int,
   :pixels, :pointer,
   :userdata, :pointer,
   :_locked, :int,
   :_lock_data, :pointer,
   :clip_rect, SDL_Rect,
   :map, :pointer,
   :refcount, :int
 end



 attach_function :SDL_CreateWindow, [:string, :int,:int, :int,:int, :uint32], :SDL_Window
 attach_function :SDL_GetWindowSize, [:SDL_Window, :int_out, :int_out], :void
 attach_function :SDL_DestroyWindow, [:SDL_Window], :void

 attach_function :SDL_CreateRenderer, [:SDL_Window, :int, :uint32], :SDL_Renderer
 attach_function :SDL_DestroyRenderer, [:SDL_Renderer], :void

 attach_function :SDL_CreateWindowAndRenderer, [:int, :int, :uint32, \
                                                :SDL_Window_out, :SDL_Renderer_out], :int

 attach_function :SDL_CreateTexture, [:SDL_Renderer, :uint32, :int, :int, :int], :SDL_Texture
 attach_function :SDL_CreateTextureFromSurface, [:SDL_Renderer, :SDL_Surface], :SDL_Texture
 attach_function :SDL_QueryTexture, [:SDL_Texture, :uint32_out, :int_out, :int_out, :int_out], :int
 attach_function :SDL_FreeSurface, [:SDL_Surface], :void
 attach_function :SDL_DestroyTexture, [:SDL_Texture], :void

 attach_function :SDL_GetRendererInfo, [:SDL_Renderer, :SDL_RendererInfo_out], :int
 attach_function :SDL_RenderCopy, [:SDL_Renderer, :SDL_Texture, SDL_Rect, SDL_Rect], :int
 attach_function :SDL_RenderClear, [:SDL_Renderer], :int
 attach_function :SDL_RenderPresent, [:SDL_Renderer], :void
 attach_function :SDL_SetRenderTarget, [:SDL_Renderer, :SDL_Texture], :int

 attach_function :SDL_GetRenderDrawColor, [:SDL_Renderer, :uint8_out,:uint8_out,:uint8_out,:uint8_out], :int
 attach_function :SDL_SetRenderDrawColor, [:SDL_Renderer, :uint8,:uint8,:uint8,:uint8], :int

 SDL_WINDOWPOS_UNDEFINED  = 0x1FFF0000
 SDL_WINDOWPOS_CENTERED   = 0x2FFF0000

 SDL_WINDOW_FULLSCREEN    = 0x00000001         # fullscreen window 
 SDL_WINDOW_OPENGL        = 0x00000002             # window usable with OpenGL context 
 SDL_WINDOW_SHOWN         = 0x00000004              # window is visible 
 SDL_WINDOW_HIDDEN        = 0x00000008             # window is not visible 
 SDL_WINDOW_BORDERLESS    = 0x00000010         # no window decoration 
 SDL_WINDOW_RESIZABLE     = 0x00000020          # window can be resized 
 SDL_WINDOW_MINIMIZED     = 0x00000040          # window is minimized 
 SDL_WINDOW_MAXIMIZED     = 0x00000080          # window is maximized 
 SDL_WINDOW_INPUT_GRABBED = 0x00000100      # window has grabbed input focus 
 SDL_WINDOW_INPUT_FOCUS   = 0x00000200        # window has input focus 
 SDL_WINDOW_MOUSE_FOCUS   = 0x00000400        # window has mouse focus 
 SDL_WINDOW_FULLSCREEN_DESKTOP = SDL_WINDOW_FULLSCREEN | 0x00001000
 SDL_WINDOW_FOREIGN       = 0x00000800        # window not created by SDL 
 SDL_WINDOW_ALLOW_HIGHDPI = 0x00002000        # window should be created in high-DPI mode if supported 

 SDL_RENDERER_SOFTWARE     = 0x00000001,     # The renderer is a software fallback
 SDL_RENDERER_ACCELERATED  = 0x00000002,     # The renderer uses hardware acceleration
 SDL_RENDERER_PRESENTVSYNC = 0x00000004,     # Present is synchronized with the refresh rate
 SDL_RENDERER_TARGETTEXTURE = 0x00000008     # The renderer supports rendering to texture

 enum_consts \
 :SDL_TEXTUREACCESS_STATIC,     0, # Changes rarely, not lockable
 :SDL_TEXTUREACCESS_STREAMING,     # Changes frequently, lockable
 :SDL_TEXTUREACCESS_TARGET        # Texture can be used as a render target
end

module SDL2
 module Gfx 
  extend FFI::Library
  ffi_lib "libSDL2_gfx"
  attach_function :lineRGBA, [:pointer, :int16,:int16,:int16,:int16, :uint8,:uint8,:uint8,:uint8], :int
  attach_function :rectangleRGBA, [:pointer, :int16,:int16,:int16,:int16, :uint8,:uint8,:uint8,:uint8], :int
  attach_function :boxRGBA,       [:pointer, :int16,:int16,:int16,:int16, :uint8,:uint8,:uint8,:uint8], :int
  attach_function :circleRGBA,       [:pointer, :int16,:int16,:int16, :uint8,:uint8,:uint8,:uint8], :int
  attach_function :filledCircleRGBA, [:pointer, :int16,:int16,:int16, :uint8,:uint8,:uint8,:uint8], :int
 end
end

module SDL2
 module Image
  extend FFI::Library
  ffi_lib "libSDL2_image"

  extend SDL2::EnumUtil

  typedef :pointer, :SDL_Surface

  attach_function :IMG_Init, [:int], :int
  attach_function :IMG_Quit, [], :void
  attach_function :IMG_Load, [:string], SDL2::SDL_Surface.by_ref

  def self.IMG_GetError
   SDL2.SDL_GetError
  end
  
  enum_consts \
   :IMG_INIT_JPG,  0x00000001,
   :IMG_INIT_PNG,  0x00000002,
   :IMG_INIT_TIF,  0x00000004,
   :IMG_INIT_WEBP, 0x00000008
 end
end

module SDL2
 module Ttf
  extend FFI::Library
  ffi_lib "libSDL2_ttf"

  attach_function :TTF_Init, [], :int
  attach_function :TTF_WasInit, [], :int
  attach_function :TTF_Quit, [], :void

  def self.TTF_GetError
   SDL2.SDL_GetError
  end

  typedef :pointer, :TTF_Font
  attach_function :TTF_OpenFont, [:string, :int], :TTF_Font
  attach_function :TTF_CloseFont, [:TTF_Font], :void

  typedef :pointer, :SDL_Surface
  typedef :pointer, :int_out
  attach_function :TTF_RenderText_Solid, [:TTF_Font, :string, SDL_Color.by_value], :SDL_Surface
  attach_function :TTF_SizeText, [:TTF_Font, :string, :int_out, :int_out], :int

  attach_function :TTF_RenderUTF8_Solid, [:TTF_Font, :string, SDL_Color.by_value], :SDL_Surface
  attach_function :TTF_SizeUTF8, [:TTF_Font, :string, :int_out, :int_out], :int

  attach_function :TTF_FontHeight, [:TTF_Font], :int
  attach_function :TTF_FontLineSkip, [:TTF_Font], :int
  attach_function :TTF_FontAscent, [:TTF_Font], :int
  attach_function :TTF_FontDescent, [:TTF_Font], :int
 end
end

