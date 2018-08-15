Namespace myapp3d

#Import "<std>"
#Import "<mojo>"
#Import "<mojo3d>"

Using std..
Using mojo..
Using mojo3d..

' canvas textured box

Class Panel Extends View

	#rem monkeydoc Window content view.
	
	During layout, the window's content view is resized to fill the window.
	
	#end	
	Property ContentView:View()
	
		Return _contentView
	
	Setter( contentView:View )
	
		If _contentView RemoveChildView( _contentView )
		
		_contentView=contentView
		
		If _contentView AddChildView( _contentView )
		
	End

	Method OnLayout() Override
	
		If _contentView _contentView.Frame=Rect
	End

	Field _clearColor:=Color.Grey
	Field _clearEnabled:=True
	Field _contentView:View
	Field _frame:Recti

	Method LayoutPanel()
		Measure()		
		UpdateLayout()
	End
	

	Field _shader:Shader
	Field _texture:Texture
	Field _canvas:Canvas
	Field _material:PbrMaterial
	Field _dim:Boxf
	Field _box:Model	
	Field _body:RigidBody
	Field _frameCount:Int

	Method New()
		_texture=New Texture(256,256,PixelFormat.RGBA8,TextureFlags.Filter)		
		_canvas=New Canvas(New Image(_texture,_shader))		
		_material=New PbrMaterial( Color.White, 0.5, 0.5 )
		_material.ColorTexture=_texture
		_dim=New Boxf(-10,-10,-1,10,10,0 )

		_box=Model.CreateBox(_dim,1,1,1,_material)
		_box.Move(10,10,10)
		_box.Rotate(-22,0,0)
		
		Local collider:=_box.AddComponent<BoxCollider>()
		collider.Box=_dim				
		_body=_box.AddComponent<RigidBody>()
		_body.CollisionGroup=64
		_body.CollisionMask=127
		_body.Mass=0
	End
	
	Method OnPick(r:RayCastResult)
		Local p:=(-_box.Matrix)*r.point
		Local px:Double=(p.x-_dim.min.X)*_texture.Width/_dim.Width
		Local py:Double=(_dim.max.Y-p.y)*_texture.Height/_dim.Height
		Print "pick:"+px+","+py
	End

	Method Refresh()	
		_canvas.Clear(Color.Brown)
		_canvas.DrawText("Hello From Mojo3D",10,10)
		_canvas.DrawText("Frame = "+_frameCount,10,30)
		_canvas.Flush()
		_frameCount+=1
	End
	
End

Class MyWindow Extends Window
	
	Field _scene:Scene
	Field _camera:Camera
	Field _light:Light
	Field _ground:Model
	Field _panel:Panel
		
	Method New( title:String="Simple mojo3d app",width:Int=640,height:Int=480,flags:WindowFlags=WindowFlags.Resizable )
		
		Super.New( title,width,height,flags )
	End
	
	Method OnCreateWindow() Override
		
		'create (current) scene
		_scene=New Scene
		_scene.ClearColor = New Color( 0.2, 0.6, 1.0 )
		_scene.AmbientLight = _scene.ClearColor * 0.25
		_scene.FogColor = _scene.ClearColor
		_scene.FogNear = 1.0
		_scene.FogFar = 200.0
		
		'create camera
		_camera=New Camera( Self )
		_camera.AddComponent<FlyBehaviour>()
		_camera.Move( 0,2.5,-20 )
		
		'create light
		_light=New Light
		_light.CastsShadow=True
		_light.Rotate( 45, 45, 0 )
		
		'create ground
		Local groundBox:=New Boxf( -100,-1,-100,100,0,100 )
		Local groundMaterial:=New PbrMaterial( Color.Lime )
		_ground=Model.CreateBox( groundBox,1,1,1,groundMaterial )
		_ground.CastsShadow=False
		
		_panel=New Panel
				
	End

	Method UpdatePanel()		
		Local r:=_camera.MousePick( 127 )
		If r
			If r.body=_panel._body
				_panel.OnPick(r)
			Endif
		Endif	
		_panel.Refresh()
	End
		
	
	Method OnRender( canvas:Canvas ) Override
		
		UpdatePanel()
					
		RequestRender()

		_scene.Update()
		_camera.Render( canvas )
		canvas.DrawText( "FPS="+App.FPS,0,0 )
	End
	
End

Function Main()

	New AppInstance
	
	New MyWindow
	
	App.Run()
End
