' smooth scrolling grid view in a generic mojox application by nitrologic

#Import "<std>"
#Import "<mojo>"
#Import "<mojox>"
#Import "<drawline>"

'#Import "<mojolabs>"

#Import "modular.theme.json"

Using std..
Using mojo..
Using mojox..

Alias DRect:Rect<Double>

Const MinZoom:Double=0.5
Const MinWidth:=32
Const MinHeight:=24
Const DefaultWindowFlags:WindowFlags=WindowFlags.HighDPI|WindowFlags.Resizable

Alias JsonFields:StringMap<JsonValue>

Struct Prefs
	Field skin:="asset::modular.theme.json"
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
		json["skin"]=New JsonString(skin)
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
		skin=json["skin"].ToString()
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

Class Grid Extends View
	Field bg:=Color.Silver
	Field fg:=Color.Grey
	
	Field shape:=New Shape
	Field context:=New Context
	
	Field org:XY
	Field vel:XY

	Field grid:=32
	Field zoom:=2.5
	
	Method New()
		shape.Plot(New XY(0,0),10)
	End
	
	Method OnUpdate()
		org+=vel
		vel*=0.972
	End
	
	Field mouseXY:Vec2i
	
	Method OnMouseEvent( event:MouseEvent ) Override	
		Local xy:=event.Location
		If event.Type=EventType.MouseWheel
			zoom+=event.Wheel.y/16.0
			Return
		Endif

		If event.Type=EventType.MouseDown
			vel*=0
			mouseXY=xy
		Endif

		If event.Type=EventType.MouseUp
		Endif

		If event.Type=EventType.MouseMove And event.Button
			Local delta:=xy-mouseXY			
			vel=vel*0.5+delta
		Endif		
		mouseXY=xy
	End

	Method OnKeyEvent( event:KeyEvent ) Override
		Local mask:=event.Modifiers
		If mask&Modifier.Control And event.Type=EventType.KeyDown
'			Select event.Key
'			End
		Endif			
		Super.OnKeyEvent(event)
	End

	Method OnRender(canvas:Canvas) Override		
		OnUpdate()		
		
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

		RequestRender()
	End
	
End

Class ModularWindow Extends Window

	Field docks:DockingView	
	Field topView:DockingView
	Field bottomView:TabView
	Field leftView:View
	Field rightView:TabView
	Field content:TabView
	Field menubar:MenuBar
	Field toolbar:GridView
	Field commandline:TextField
	Field scale:Double
	Field frame:Recti

	Method New()		
		Super.New("Modular",prefs.frame,DefaultWindowFlags)		
		Fullscreen=prefs.fullscreen 
		SetTheme(prefs.skin)
		AddDocks()
		SetZoom(prefs.scale)
	End
	
	Function Reset()
		libc.rename(PrefsPath,PrefsPath+".old")
		libc.remove(PrefsPath)
		App.Terminate()
	End

	Method Save()
		prefs.top=topView.Height
		prefs.bottom=bottomView.Height
		prefs.left=leftView.Width
		prefs.right=rightView.Width
		prefs.menuwidth=menubar.Width
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
	
	Method CreateCommandLine:TextField()
		Return New TextField(">",8192)
	End

	Method AddDocks()
		menubar=CreateMenu()
		toolbar=CreateTools()
		topView=New DockingView

		commandline=CreateCommandLine()

		topView.ContentView=commandline
		
		topView.AddView(menubar,"left",prefs.menuwidth,true)
		topView.AddView(toolbar,"right",prefs.toolswidth,True)

		bottomView=CreateTabs()		
		leftView=CreateFileTree()
		content=CreateTabs()
		rightView=CreateTabs()
		docks=New DockingView		
		docks.AddView(topView,"top",prefs.top, True)
		docks.AddView(bottomView,"bottom",prefs.bottom,True)
		docks.AddView(leftView,"left",prefs.left,True)
		docks.AddView(rightView,"right",prefs.right,True)
		docks.ContentView=content				
		Local grid:=New Grid()
		Local sceneTree:=CreateTree()
		AddTab(rightView,"Scene",sceneTree)		
		AddTab(bottomView,"Help",New HtmlView())		
		AddTab(content,"Grid",grid)
		ContentView=docks
		docks.ContentView.MakeKeyView()
	End		

	Function DirectoryTree( path:String,parent:TreeView.Node )	
		For Local f:=Eachin LoadDir( path )		
			Local p:=path+"/"+f			
			Local node:=New TreeView.Node( f,parent )
			If GetFileType( p )=FileType.Directory DirectoryTree( p,node )
		Next
	End
		
	Method CreateTools:GridView()
		Local bar:=New GridView(8,2)		
		bar.AddView(New Button("Grab"),0,0)
		bar.AddView(New Button("Select"),0,0)
		bar.AddView(New Button("Plot"),1,0)
		bar.AddView(New Button("Edit"),2,0)			
		Return bar
	End
	
	Method CreateMenu:MenuBar()
		Local fileMenu:=New Menu( "File" )	
		Local recentFiles:=New Menu( "Recent Files..." )					

		Local editMenu:=New Menu( "Edit" )		
		AddAction(editMenu,"Cut",Key.X,Modifier.Control).Triggered=Cut
		AddAction(editMenu,"Copy",Key.C,Modifier.Control).Triggered=Copy
		AddAction(editMenu,"Paste",Key.V,Modifier.Control).Triggered=Paste

		Local viewMenu:=New Menu( "View" )

		AddAction(fileMenu,"New",Key.N,Modifier.Control).Triggered=Create
		AddAction(fileMenu,"Open",Key.O,Modifier.Control).Triggered=Open
		AddAction(fileMenu,"Close",Key.W,Modifier.Control).Triggered=Close
		AddAction(fileMenu,"Quit",Key.Q,Modifier.Alt).Triggered=Quit		

		AddAction(viewMenu,"Fullscreen",Key.F11).Triggered=ToggleFullscreen
		AddAction(viewMenu,"Maximized",Key.F12).Triggered=ToggleMaximized
		AddAction(viewMenu,"Zoom In",Key.Equals,Modifier.Control).Triggered=ZoomIn
		AddAction(viewMenu,"Zoom Out",Key.Minus,Modifier.Control).Triggered=ZoomOut

		Local helpMenu:=New Menu( "Help" )
		AddAction(helpMenu,"Reset to Factory Defaults").Triggered=Reset

		Local menuBar:=New MenuBar		
		menuBar.AddMenu( fileMenu )
		menuBar.AddMenu( editMenu )
		menuBar.AddMenu( viewMenu )
		menuBar.AddMenu( helpMenu )
		Return menuBar
	End

	Function AddAction:Action(menu:Menu,name:String,hotkey:Key=Key.None,modifiers:Modifier=Modifier.None)
		Local action:=New Action(name)
		action.HotKey=hotkey
		action.HotKeyModifiers=modifiers
		menu.AddAction(action)
		Return action
	End

	Method AddTab(tabView:TabView, title:String, content:View)
		tabView.AddTab( title,content )
		tabView.CurrentIndex=0		
	End
	
	Method CreateTabs:TabView()
		Local tabView:=New TabView( TabViewFlags.ClosableTabs|TabViewFlags.DraggableTabs )		
		tabView.RightClicked=Lambda()		
			Local menu:=New Menu
			menu.AddAction( "Action 1" )
			menu.AddAction( "Action 2" )
			menu.AddAction( "Action 3" )			
			menu.Open()
		End		
		tabView.CloseClicked=Lambda( index:Int )		
			tabView.RemoveTab( index )		
			If tabView.CurrentView Or Not tabView.NumTabs Return
			If index=tabView.NumTabs index-=1
			tabView.CurrentIndex=index
		End		
		Return tabView		
	End

	Method CreateTree:TreeView()
		Local treeView:=New TreeView		
		treeView.NodeClicked+=Lambda( node:TreeView.Node )
			Alert( "Node clicked: node.Text=~q"+node.Text+"~q" )
		End		
		treeView.NodeExpanded+=Lambda( node:TreeView.Node )
'			Alert( "Node expanded: node.Text=~q"+node.Text+"~q" )
		End		
		treeView.NodeCollapsed+=Lambda( node:TreeView.Node )		
'			Alert( "Node collapsed: node.Text=~q"+node.Text+"~q" )
		End		
		treeView.RootNode.Text="Origin"

'		DirectoryTree( dir,treeView.RootNode )		
		Return treeView
	End		

	Method CreateFileTree:TreeView()
		Local treeView:=New TreeView		
		treeView.NodeClicked+=Lambda( node:TreeView.Node )
			Alert( "Node clicked: node.Text=~q"+node.Text+"~q" )
		End		
		treeView.NodeExpanded+=Lambda( node:TreeView.Node )
'			Alert( "Node expanded: node.Text=~q"+node.Text+"~q" )
		End		
		treeView.NodeCollapsed+=Lambda( node:TreeView.Node )		
'			Alert( "Node collapsed: node.Text=~q"+node.Text+"~q" )
		End		
		treeView.RootNode.Text=CurrentDir()
		DirectoryTree( CurrentDir(),treeView.RootNode )		
		Return treeView
	End		

	Method AddUI()
		Local list:=New ListView
		list.AddItem( "listview" )		
		list.ItemClicked+=Lambda( item:ListView.Item )
			Local index:=list.IndexOfItem( item )			
			Print "Item "+index+" clicked"
		End		
		ContentView=list
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
	
'	mojolabs.EnableHighDPI()

	New AppInstance

	Local filePrefs:=JsonObject.Load(PrefsPath)
	If filePrefs 
		prefs.FromJson(filePrefs)		
		If prefs.Invalid()
			ModularWindow.Reset()
			Print "Invalid Prefs - invoked Factory Reset"
			Return
		Endif
	Endif
	
	New ModularWindow
	
	App.Run()
End

