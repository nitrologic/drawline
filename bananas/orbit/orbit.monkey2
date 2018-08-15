' monkey2 orbit experiments
'
' simulation keys
'
' key1 - binary stars
' key2 - solar system
' key3 - ship tests
' key4 - tile tests
'
' projection keys
'
' key L - Linear
' key P - Powered
' 
' operations
' key e - earth

#Import "<std>"
#Import "<mojo>"
#Import "<mojolabs>"

#Import "<drawline>"
#Import "<sdl2>"
#Import "<sdl2-mixer>"

#Import "assets/vectorfont.json"

Using std..
Using mojo..

Alias I:Int

Alias GridContext:PowerContext
'Alias GridContext:SmoothContext

Alias Micros:Long
Alias Gram:Double

Global Title:="GameGrid"

' v = (4.pi.r.r.r)/3
' r = ((3.v)/(4.pi))^0.33

Global G:=.01
Global Speed:=0.002
Global Steps:=256

Class Mass
	Field grams:Gram
	Field position:XY
	Field velocity:XY	
	Field radius:=1.0
	
	Method New()
	End

	Method New(weight:Gram,pos:XY,vel:XY)
		grams=weight
		position=pos
		velocity=vel
		radius=0.2+Pow((3*weight)/(4*Pi),1.0/3)
		Print "radius="+radius
	End
	
	Const None:=New Mass()

	Method Move()
		position+=velocity*Speed
	End
	
	Function Attract(m0:Mass,m1:Mass)
		Local distance:=m0.position.Distance(m1.position)
		Local f:=(m1.position-m0.position)/(distance*distance*distance)		
		m0.velocity+=f*m1.grams*G
		m1.velocity-=f*m0.grams*G
	End
	
	Method Draw(context:GridContext) Virtual
		context.Plot(position,1+radius)
	End
End

Alias Radians:Double

Class Ship Extends Mass	
	Field rotation:Radians

	Method New(mass:Gram,pos:XY,vel:XY)
		Super.New(mass,pos,vel)
	End

	Method Draw(context:GridContext) Override
		Local nose:=New XY(1,0)
		nose*=20
		context.Plot(position+nose,200*radius)
		context.Plot(position,200*radius)
	End
	
	Method Turn(angle:Radians)
		rotation+=angle
	End
End

Alias MassList:Stack<Mass>

Class Universe
	Field bodies:=New MassList
	Field colormap:=New Map<Mass,Color>
	
	Method New()
	End
	
	Method AddBody:Mass(weight:Gram,position:XY,velocity:XY,color:Color=Null)
		Local mass:=New Mass(weight,position,velocity)
		bodies.Add(mass)
		If color colormap[mass]=color
		Return mass
	End
	
	Method AddBody(body:Mass)
		bodies.Add(body)
	End

	Method Update()		
		Local mass:=bodies.ToArray()
		Local n:=mass.Length		
		For Local s:=0 Until Steps		
			For Local i:=0 Until n
				Local m0:=mass[i]
				For Local j:=i+1 Until n
					Local m1:=mass[j]
					Mass.Attract(m0,m1)
				Next
			Next
			For Local mass:=Eachin bodies
				mass.Move()
			Next
		Next
	End

End

Enum Button
	Left,
	Right,
	Up,
	Down,
	A,
	B
End

Alias KeyButtons:Map<Key,Button>

Class GridPlayer
	
	Struct Action
	End
	
	Field buttonActions:=New Map<Key,Action>
	Field keys:=New KeyButtons
	Field buttonState:=New Bool[6]
	
	Method New()
		keys[Key.Left]=Button.Left
	End

	Method KeyDown(event:KeyEvent)
		Select event.Type
			Case EventType.KeyDown
				Local key:=event.Key
				If keys.Contains(key)
					Local button:=keys[key]
					buttonState[button]=True
				Endif				
			Case EventType.KeyUp
				Local key:=event.Key
				If keys.Contains(key)
					Local button:=keys[key]
					buttonState[button]=False
				Endif				
		End
	End
	
	Method Axis:Double(index:Int)
		Return 0
	End

End

Class GridGame
	
	Field world:=New Universe
	Field ship:Ship
	Field player0:GridPlayer
	Field focus:=Mass.None
	
	Method New(player:GridPlayer)
		player0=player
	End
	
	Method OnKey(key:Key)
		Select key
			Case Key.M
				SetFocalMass(2)
			Case Key.E
				SetFocalMass(1)
			Case Key.S
				SetFocalMass(0)
			Case Key.O
				focus=Mass.None
		End
	End

	Method SetFocalMass(index:Int)
		If index<world.bodies.Length
			Local body:=world.bodies[index]
			focus=body
		Else
			focus=Mass.None
		Endif
	End

	Method Draw(context:GridContext)
		context.Push(focus.position,focus.radius)	
		For Local mass:=Eachin world.bodies
			Local color:=world.colormap[mass]
			If Not color color=Color.White 
			context.Foreground(color)
			mass.Draw(context)		
		Next		
		context.Pop()
	End

	Method SetSim(index:Int)
		Clear()
		Select index 
			Case 0
				BinarySystem()
			Case 1
				SolarSystem()
			Case 2
				Title="PlayerShip1"
				ship=New Ship(.05,New XY(90,400),New XY(0,0))
				world.AddBody(ship)
		End
		SetFocalMass(0)
	End
		
	Method Clear()
		world=New Universe
	End
	
	Method BinarySystem()
		Title="BinarySystem"
		world.AddBody(800,New XY(110,200),New XY(0,1))
		world.AddBody(800,New XY(410,200),New XY(0,-1))		
	End

	Method SolarSystem()
		Title="SolarSystem"
		world.AddBody(800,New XY(0,0),New XY(0,0),Color.Yellow)

		world.AddBody(10,New XY(-300,0),New XY(0,1),Color.Aqua)
		world.AddBody(.0001,New XY(-320,0),New XY(0.02,1.4),Color.Silver)

		world.AddBody(10,New XY(-500,0),New XY(0,1),Color.Red)
		world.AddBody(.0001,New XY(-520,0),New XY(0.02,1.4),Color.Silver)		
	End		
	
	Method Begin(grid:GameGrid,index:Int)
		SetSim(index)
	End
	
	Method Update()
		world.Update()
	End
	
End

Alias GridGames:Stack<GridGame>

Global Grey0:=Color.FromARGB($ff222222)
Global Grey1:=Color.FromARGB($ff444444)
Global Grey2:=Color.FromARGB($ff666666)

Class GameGrid

	Field bg:=Grey0
	Field fg:=Grey1
	
	Field context:=New GridContext
	
	Field org:XY
	Field vel:XY

	Field grid:=32
	Field zoom:=2.5
	Field zoomSpeed:=0.0
	Field zoomPos:XY

	Field power:=0.5
	Field powerSpeed:=0.0

	Field owner:View
	
	Field vectorFont:=New VectorFont
	
	Field player0:GridPlayer
		
	Method New(view:View)		
		owner=view
		vectorFont=LoadFont("asset::vectorfont.json")
		player0=New GridPlayer()
	End
	
	Method KeyDown(event:KeyEvent)
		player0.KeyDown(event)
	End
	
	Method ZoomPos(v:Double, pos:XY)
		zoomSpeed=v
		zoomPos=pos
	End
	
	Method PowerPos(v:Double, pos:XY)
		powerSpeed+=v
'		zoomPos=pos
	End

	Method Update()
		org+=vel
		vel*=0.972		
		Local z0:=zoomPos/zoom
		zoom+=zoomSpeed
'		Local z1:=zoomPos/zoom
'		org-=(z1-z0)
		zoomSpeed*=0.88		
		
		power+=powerSpeed
		powerSpeed*=0.88

		If power<Epsilon power=Epsilon
	End
			
	Method DrawGrid(radius:I,increment:I,th:R)		
		For Local i:=-radius To radius Step increment
			context.Line(New XY(radius,i),New XY(-radius,i),th)
			context.Line(New XY(i,radius),New XY(i,-radius),th)
		Next
	End
			
	Method Render(canvas:Canvas,games:GridGames)
		
		context.BeginPaint(canvas,vectorFont)
		
		Local w:=canvas.Viewport.Width
		Local h:=canvas.Viewport.Height

		canvas.Translate(w/2,h/2)

		canvas.Clear(bg)
		canvas.Color=fg
						
		canvas.Color=Color.White
				
		context.Origin(org,power)
		context.Zoom(zoom)	
		context.Foreground(Grey2)
	
		context.Text(New XY(50,80),.060,"Orbit Version 0.001")
		context.Text(New XY(50,120),.052,Title)
		context.Foreground(Color.SeaGreen)
		context.Text(New XY(20,-20),.085,"frequency 0.2")
		
		context.Foreground(Color.FromARGB($77223366))
		DrawGrid(512,32,0.2)
		context.Foreground(Color.FromARGB($ff226633))
		DrawGrid(8192,512,0.1)
		
		For Local game:=Eachin games
			game.Draw(context)
		Next
		context.EndPaint()		
	End	
End

Class Shape Extends IntList
	Method AddLine(x0:Int,y0:Int,x1:Int,y1:Int)
		Add(x0)
		Add(y0)
		Add(x1)
		Add(y1)
	End
End

Function LoadFont:VectorFont(path:String)
	Local result:=New VectorFont
	Local json:=JsonObject.Load(path)
	Local vectors:=json.GetValue("vectorfont")		
	Local glyphs:=vectors.ToArray()		
	For Local i:=0 Until glyphs.Length
		Local value:=glyphs[i].ToObject()			
		Local charcode:=value["charcode"]
		Local code:Int=charcode.ToNumber()
		If Not code code=charcode.ToString()[0]
		Local drawlist:=value["drawlist"].ToArray()
		Local n:=drawlist[0].ToNumber()
		Local shape:=New Shape
		For Local j:=0 Until n
			Local x0:=drawlist[1+j*4].ToNumber()
			Local y0:=drawlist[2+j*4].ToNumber()
			Local x1:=drawlist[3+j*4].ToNumber()
			Local y1:=drawlist[4+j*4].ToNumber()
			shape.AddLine(x0,y0,x1,y1)
		Next
		Local data:=shape.ToArray()
		result[code]=data
	Next
	Return result
End



Global FragmentSize:=1024
Const DefaultVolume:=0.2

Class OrbitSynth Extends MonoSynth
	Field detune:V=1.0
	Field detune0:V=1.0

	Field fall:V
	Field vel:V

	Field fade:V=DefaultVolume
	Field fade0:V=DefaultVolume

	Field detuneBuffer:=New V[FragmentSize]
	Field fadeBuffer:=New V[FragmentSize]

	Field overdrive:=New V[FragmentSize]
	Field gain:=New V[FragmentSize]
	Field wet:=New V[FragmentSize]
	Field dry:=New V[FragmentSize]
	Field falloff:=New V[FragmentSize]

	Method Note(note:Note)
		fall=-1
		vel=-0.01
		Super.NoteOn(note)
	End
	
	Method Write(buffer:Double[],samples:Int)		

		detune+=fall*samples/AudioFrequency
		fall+=vel*samples/AudioFrequency
		If detune<=0 Return

		For Local i:=0 Until samples
			detuneBuffer[i]=detune0+i*(detune-detune0)/samples
			fadeBuffer[i]=fade0+i*(fade-fade0)/samples
			overdrive[i]=20

			gain[i]=1.0/20
			wet[i]=1
			dry[i]=1
			falloff[i]=1.5
		Next			
		detune0=detune
		fade0=fade
		FillAudioBuffer(buffer,samples,detuneBuffer,fadeBuffer)	
	End

End

Class GridSynth

	Const WriteAhead:=8192
	Const MiddleC:=New Note(60,40)

	Const HighWhite:=New Note(92,20)
	Const HighC:=New Note(77,40)
	
	Field buffer:=New Double[FragmentSize*2]

	Field synth0:=New OrbitSynth()
	Field synth1:=New OrbitSynth()
	Field audioPipe:=AudioPipe.Create()

	Method New()		
		OpenAudio()
	End
	
	Method Test()
		synth0.SetTone(4,0)
		synth0.Note(HighWhite)			
'		synth1.SetTone(3,3)
'		synth1.Note(HighC)
	End

	Field audioSpec:sdl2.SDL_AudioSpec
			
	Method OpenAudio()
		Local spec:=New sdl2.SDL_AudioSpec
		spec.freq=AudioFrequency	
		spec.format = sdl2.AUDIO_S16
		spec.channels = 2
		spec.samples = FragmentSize
		spec.callback = AudioPipe.Callback
		spec.userdata = audioPipe.Handle()
		
'		sdl2.Mix_CloseAudio()		
		Local error:Int = sdl2.SDL_OpenAudio(Varptr spec,Varptr audioSpec)		
		If error
			Print "error="+error+" "+String.FromCString(sdl2.SDL_GetError())
		Else
			Print "Audio Open freq="+audioSpec.freq
			AudioFrequency=audioSpec.freq
		Endif				
		sdl2.SDL_PauseAudio(0)
	End

	Method UpdateAudio()
		While True
			Local buffered:=audioPipe.writePointer-audioPipe.readPointer
			If buffered>=WriteAhead Exit
			Local samples:=FragmentSize
			Local buffer:=FillAudioBuffer(samples)
			Local pointer:=Varptr buffer[0]
			audioPipe.WriteSamples(pointer,samples*2)
		Wend
	End
	
	Method FillAudioBuffer:Double[](samples:Int)		
		For Local i:=0 Until samples
			buffer[i*2+0]=0
			buffer[i*2+1]=0
		Next		
		synth0.Write(buffer,samples)
		synth1.Write(buffer,samples)
		Duration+=samples			
		Return buffer
	End


End

Class OrbitWindow Extends Window

	Field grid:GameGrid
	Field games:GridGames
	Field active:GridGame
	Field scale:Double
	Field frame:Recti
	Field player:GridPlayer
	Field synth:GridSynth

	Method New()		
		Super.New("Orbit",prefs.frame,DefaultWindowFlags)		
		Fullscreen=prefs.fullscreen 
		SetZoom(prefs.scale)		
		grid=New GameGrid(Self)
		synth=New GridSynth()
		SetWorld(1)
	End
	
	Method SetWorld(index:Int)
		synth.Test()
		games=New GridGames()
		Local game:=New GridGame(player)
		game.Begin(grid,index)
		games.Add(game)
		active=game
	End
	
	Method Close()
		Save()
		App.Terminate()
	End

	Method OnKeyEvent( event:KeyEvent ) Override
		Local mask:=event.Modifiers
		If event.Type=EventType.KeyDown
			If mask&Modifier.Control 
'				Select event.Key
'				End
			Else
				Select event.Key
					Case Key.F11
						ToggleFullscreen()
					Case Key.Escape
						Close()
					Case Key.Key1
						SetWorld(0)
					Case Key.Key2
						SetWorld(1)
					Case Key.Key3
						SetWorld(2)
					Default 
						active.OnKey(event.Key)
						grid.KeyDown(event)
				End
			Endif
		Endif			
		Super.OnKeyEvent(event)
	End

	Field mouseXY:Vec2i
	Field mouseTime:Micros
	
	Method OnMouseEvent( event:MouseEvent ) Override	
		Local t0:=mouseTime
		Local t1:=Microsecs()
		mouseTime=t1
		Local delta:=t1-t0
		
		Local xy:=event.Location
		If event.Type=EventType.MouseWheel
			If event.Modifiers & Modifier.Control
				grid.PowerPos(event.Wheel.y/120.0,xy)
			Else
				grid.ZoomPos(event.Wheel.y/20.0,xy)
			Endif
			Return
		Endif

		If event.Type=EventType.MouseDown
			If event.Button=MouseButton.Right
				grid.vel=Null
				mouseXY=xy
			Endif
		Endif

		If event.Type=EventType.MouseUp
'			If delta>500 grid.vel=Null
		Endif

		If event.Type=EventType.MouseMove And event.Button=MouseButton.Right
			Local delta:=mouseXY-xy			
			grid.vel=delta*0.2
'			grid.vel=grid.vel*0.5+delta
'			grid.vel=grid.vel*0.05+delta
		Endif		
'		mouseXY=xy
	End

	Method OnRender(canvas:Canvas) Override				
'		synth.synth1.Detune(0.98)
		synth.UpdateAudio()
		For Local game:=Eachin games
			game.Update()
		Next
		grid.Update()		
		grid.Render(canvas,games)
		RequestRender()
	End

	Function Reset()
		libc.rename(PrefsPath,PrefsPath+".old")
		libc.remove(PrefsPath)
'		If terminate App.Terminate()
	End

	Method Save()
		Local view:=Self
		prefs.top=view.Height
		prefs.bottom=view.Height
		prefs.left=view.Width
		prefs.right=view.Width
		prefs.scale=scale
		prefs.frame=frame
		prefs.fullscreen=Fullscreen
		Local obj:=prefs.ToJson()				
		Local str:=obj.ToJson()
		SaveString(str,PrefsPath)
		Print "Saved to "+PrefsPath
	End

	Method OnWindowEvent( event:WindowEvent ) Override	
		Select event.Type
			Case EventType.WindowClose
				Print "Window Close"
				Save()
			Case EventType.WindowMoved
				If Not Fullscreen And Not Maximized And Not Minimized 
					frame=Frame				
				Endif
			Case EventType.WindowResized
				If Not Fullscreen And Not Maximized And Not Minimized 
'					Print "Size"
					frame=Frame				
					SetZoom(scale)					
				Endif
		End
		Super.OnWindowEvent(event)
	End


' triggers

	Method Cut()
	End

	Method Copy()
	End

	Method Paste()
	End

	Method Create()
	End

	Method Open()
	End
		
	Method Quit()
		Save()
		App.Terminate()
	End

	Method ToggleFullscreen()
		If Not Fullscreen frame=Frame
		Fullscreen=Not Fullscreen
	End

	Method ToggleMaximized()
		If Not Fullscreen 
			If Maximized
				Restore()
			Else
				Maximize()
			Endif
		Endif
	End

	Method SetZoom(zoom:Double)
		scale=Max(zoom,MinZoom)
		prefs.scale=scale
		App.Theme.Scale=New Vec2f( scale,scale )		
	End

	Method SetTheme(path:String)
		App.Theme.Load( path )		
	End
	
	Method ZoomIn()
		SetZoom(prefs.scale+0.0625)
	End

	Method ZoomOut()
		SetZoom(prefs.scale-0.0625)
	End
	
End

Const MinZoom:Double=0.5
Const MinWidth:=32
Const MinHeight:=24
Const DefaultWindowFlags:WindowFlags=WindowFlags.HighDPI|WindowFlags.Resizable

Alias JsonFields:StringMap<JsonValue>

Struct Prefs
	Field top:Int=35
	Field bottom:int=120
	Field left:int=250
	Field right:Int=250
	Field scale:Double=1.0
	Field frame:Recti=New Recti(100,100,1720,1280)
	Field fullscreen:Bool
	
	Method Invalid:Bool()
		Return frame.Width < MinWidth Or frame.Height<MinHeight
	End

	Function JsonRect:JsonObject(rect:Recti)
		Local json:=New JsonObject()
		json["top"]=New JsonNumber(rect.Top)
		json["bottom"]=New JsonNumber(rect.Bottom)
		json["left"]=New JsonNumber(rect.Left)
		json["right"]=New JsonNumber(rect.Right)
		Return json
	End
	
	Function RectJson:Recti(obj:JsonFields)
		Local x0:=obj["left"].ToNumber()
		Local y0:=obj["top"].ToNumber()
		Local x1:=obj["right"].ToNumber()
		Local y1:=obj["bottom"].ToNumber()		
		Return New Recti(x0,y0,x1,y1)
	End

	Method ToJson:JsonObject()		
		Local json:=New JsonObject()
		json["top"]=New JsonNumber(top)
		json["bottom"]=New JsonNumber(bottom)
		json["left"]=New JsonNumber(left)
		json["right"]=New JsonNumber(right)
		json["scale"]=New JsonNumber(scale)
		json["frame"]=JsonRect(frame)		
		json["fullscreen"]=New JsonBool(fullscreen)
		Return json
	End
	
	Method FromJson:Prefs(json:JsonObject)
		top=json["top"].ToNumber()
		bottom=json["bottom"].ToNumber()
		left=json["left"].ToNumber()
		right=json["right"].ToNumber()
		scale=json["scale"].ToNumber()
		If json.Contains("fullscreen")
			fullscreen=json["fullscreen"].ToBool()
		Endif
		If json.Contains("frame")
			frame=RectJson(json["frame"].ToObject())
		Endif
		Return Self
	End

End

Global prefs:=New Prefs()
Global PrefsPath:=(AppPath()+".prefs")

Function Main()
	
	mojolabs.EnableHighDPI()
	
	New AppInstance

	Local filePrefs:=JsonObject.Load(PrefsPath)
	If filePrefs 
		prefs.FromJson(filePrefs)		
		If prefs.Invalid()
			Print "Invalid Prefs - invoking Factory Reset"
			OrbitWindow.Reset()
			prefs=New Prefs()
		Endif
	Endif
	
	New OrbitWindow
	
	App.Run()
End

