' monkey2 grid sim

' key1 - binary stars
' key2 - solar system
' key3 - ship tests

#Import "<std>"
#Import "<mojo>"
#Import "<mojolabs>"

#Import "<drawline>"

#Import "assets/vectorfont.json"

Using std..
Using mojo..

Alias Micros:Long

Alias Gram:Double

Global Title:="GameGrid"

' v = (4.pi.r.r.r)/3
' r = ((3.v)/(4.pi))^0.33

Class Mass
	Field grams:Gram
	Field position:XY
	Field velocity:XY	
	Field radius:Double
	
	Method New(mass:Gram,pos:XY,vel:XY)
		grams=mass
		position=pos
		velocity=vel
		radius=Pow((3*mass)/(4*Pi),1.0/3)
		Print "radius="+radius
	End

	Method Move()
		position+=velocity		
	End
	
	Function Attract(m0:Mass,m1:Mass)
		Local distance:=m0.position.Distance(m1.position)
		Local f:=(m1.position-m0.position)/(distance*distance*distance)
		m0.velocity+=f*m1.grams*G
		m1.velocity-=f*m0.grams*G
	End
	
	Method Draw(context:SmoothContext) Virtual
		context.Plot(position,20*radius)
	End
End

Alias Radians:Double

Class Ship Extends Mass	
	Field rotation:Radians

	Method New(mass:Gram,pos:XY,vel:XY)
		Super.New(mass,pos,vel)
	End

	Method Draw(context:SmoothContext) Override
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

Const G:Double=1.2

Class Universe
	Field bodies:=New MassList
	
	Method New()
	End
	
	Method AddBody(mass:Gram,position:XY,velocity:XY)
		bodies.Add(New Mass(mass,position,velocity))
	End
	
	Method AddBody(body:Mass)
		bodies.Add(body)
	End

	Method Update()		

		Local mass:=bodies.ToArray()
		Local n:=mass.Length
		Local gravity:=New XY		
		
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
	
	Method New(player:GridPlayer)
		player0=player
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
		world.AddBody(800,New XY(410,200),New XY(0,0))
		world.AddBody(1,New XY(110,200),New XY(0,1))
		world.AddBody(.1,New XY(90,200),New XY(0,1.12))
	End		
	
	Method Begin(grid:GameGrid,index:Int)
		SetSim(index)
	End
	
	Method Update()
		world.Update()
	End
	
	Method Draw(context:SmoothContext)
		For Local mass:=Eachin world.bodies
			mass.Draw(context)		
		Next

	End
End

Alias GridGames:Stack<GridGame>

Global Grey0:=Color.FromARGB($ff444444)
Global Grey1:=Color.FromARGB($ff222222)
Global Grey2:=Color.FromARGB($ff666666)

Class GameGrid

	Field bg:=Grey0
	Field fg:=Grey1
	
	Field context:=New SmoothContext
	
	Field org:XY
	Field vel:XY

	Field grid:=32
	Field zoom:=2.5
	Field zoomSpeed:=0.0
	Field zoomPos:XY

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
	
	Method Update()
		org+=vel
		vel*=0.972		
		Local z0:=zoomPos/zoom
		zoom+=zoomSpeed
'		Local z1:=zoomPos/zoom
'		org-=(z1-z0)
		zoomSpeed*=0.88		
	End
			
	Method Render(canvas:Canvas,games:GridGames)
		
		context.BeginPaint(canvas,vectorFont)
		
		Local w:=canvas.Viewport.Width
		Local h:=canvas.Viewport.Height		

		canvas.Clear(bg)
		canvas.Color=fg
		
		Local thick:=Abs(zoom)
		Local g:=grid*thick

		Local wide:Int=1+w/g
		Local hi:Int=1+h/g
				
		Local oy:=((org.Y Mod g)-g)Mod g
		Local ox:=((org.X Mod g)-g)Mod g
		
		Local iy:Int=math.Floor(-org.y/g)
		For Local y:=oy To h Step g						
			Local th:=thick * ((iy&3) ? 1 Else 2)
			Local rect:=New Rectf(0,y-th,w,y+th)
'			canvas.DrawRect(rect)
'			canvas.DrawRect(rect,circle,hrect2)
			context.HLin(rect)
			iy+=1
		Next
	
		Local ix:Int=math.Floor(-org.x/g)
		For Local x:=ox To w Step g
			Local th:=thick * ((ix&3) ? 1 Else 2)
			Local rect:=New Rectf(x-th,0,x+th,h)
'			canvas.DrawRect(rect)
'			canvas.DrawRect(rect,circle,vrect2)
			context.VLin(rect)
			ix+=1
		Next

		canvas.Color=Color.White
		
		context.Origin(org)
		context.Zoom(zoom)	
		context.Foreground(Grey2)
		context.Text(New XY(50,180),2,"Orbit Version 0.001")
		context.Text(New XY(50,220),2,Title)
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


Class OrbitWindow Extends Window

	Field grid:GameGrid
	Field games:GridGames
	Field scale:Double
	Field frame:Recti
	Field player:GridPlayer

	Method New()		
		Super.New("Orbit",prefs.frame,DefaultWindowFlags)		
		Fullscreen=prefs.fullscreen 
		SetZoom(prefs.scale)		
		grid=New GameGrid(Self)
		SetWorld(2)
	End
	
	Method SetWorld(index:Int)
		games=New GridGames()
		Local game:=New GridGame(player)
		game.Begin(grid,index)
		games.Add(game)		
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
			grid.ZoomPos(event.Wheel.y/20.0,xy)
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
'		prefs.FromJson(filePrefs)		
		If prefs.Invalid()
			Print "Invalid Prefs - invoking Factory Reset"
			OrbitWindow.Reset()
			prefs=New Prefs()
		Endif
	Endif
	
	New OrbitWindow
	
	App.Run()
End

