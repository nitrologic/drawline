' simple mojo game by nitrologic

#Import "<std>"
#Import "<mojo>"
#Import "<drawline>"

#Import "assets/vectorfont.json"

Using std..
Using mojo..

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
	Field menuwidth:Int=200
	Field toolswidth:Int=480
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
		json["menuwidth"]=New JsonNumber(menuwidth)
		json["toolswidth"]=New JsonNumber(toolswidth)
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
		menuwidth=json["menuwidth"].ToNumber()
		toolswidth=json["toolswidth"].ToNumber()
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

Class OrbitGrid
	
	Field bg:=Color.Silver
	Field fg:=Color.Grey
	
	Field shape:=New Shape
	Field context:=New Context
	
	Field org:XY
	Field vel:XY

	Field grid:=32
	Field zoom:=2.5

	Field owner:View
	
	Method New(view:View)		
		owner=view
		shape.Plot(New XY(0,0),10)
	End
	
	Method Update()
		org+=vel
		vel*=0.972
	End
			
	Method Render(canvas:Canvas)
		
		context.BeginPaint(canvas)
		
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
		
		context.Origin(org)
		context.Zoom(zoom)
		
		context.Plot(New XY(50,50),20)		

		context.Line(New XY(150,150),New XY(250,200),10)

' for each layer

		context.Draw(shape)
		context.EndPaint()

	End
	
End

Class OrbitWindow Extends Window

	Field grid:OrbitGrid
	Field scale:Double
	Field frame:Recti

	Method New()		
		Super.New("Orbit",prefs.frame,DefaultWindowFlags)		
		Fullscreen=prefs.fullscreen 
		SetZoom(prefs.scale)		
		grid=New OrbitGrid(Self)
	End

	Method OnKeyEvent( event:KeyEvent ) Override
		Local mask:=event.Modifiers
		If mask&Modifier.Control And event.Type=EventType.KeyDown
'			Select event.Key
'			End
		Endif			
		Super.OnKeyEvent(event)
	End

	Field mouseXY:Vec2i
	
	Method OnMouseEvent( event:MouseEvent ) Override	
		Local xy:=event.Location
		If event.Type=EventType.MouseWheel
			grid.zoom+=event.Wheel.y/16.0
			Return
		Endif

		If event.Type=EventType.MouseDown
			grid.vel*=0
			mouseXY=xy
		Endif

		If event.Type=EventType.MouseUp
		Endif

		If event.Type=EventType.MouseMove And event.Button
			Local delta:=xy-mouseXY			
'			grid.vel=grid.vel*0.5+delta
			grid.vel=grid.vel*0.05+delta
		Endif		
		mouseXY=xy
	End

	Method OnRender(canvas:Canvas) Override				
		grid.Update()		
		grid.Render(canvas)
		RequestRender()
	End

	Function Reset(terminate:Bool)
		libc.rename(PrefsPath,PrefsPath+".old")
		libc.remove(PrefsPath)
		If terminate App.Terminate()
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
					Print "Size"
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
	
	Method Close()
		Save()
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

Function Main()
	
	Local js:=LoadString("asset::vectorfont.json")
	Print js
	
'	mojolabs.EnableHighDPI()

	New AppInstance

	Local filePrefs:=JsonObject.Load(PrefsPath)
	If filePrefs 
		prefs.FromJson(filePrefs)		
		If prefs.Invalid()
			Print "Invalid Prefs - invoking Factory Reset"
			OrbitWindow.Reset(True)
			Return
		Endif
	Endif
	
	New OrbitWindow
	
	App.Run()
End

