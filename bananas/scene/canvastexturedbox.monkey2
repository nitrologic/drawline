Namespace myapp3d

#Import "<std>"
#Import "<mojo>"
#Import "<mojo3d>"

Using std..
Using mojo..
Using mojo3d..


Class MyWindow Extends Window
	
	Field _scene:Scene
	Field _camera:Camera
	Field _light:Light
	Field _ground:Model

	Field _shader:Shader
	Field _texture:Texture
	Field _canvas:Canvas
	Field _material:PbrMaterial
	Field _box:Model	

	Field _frameCount:Int
		
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
			
		'create canvas textured box
		_texture=New Texture(128,128,PixelFormat.RGBA8,TextureFlags.Filter)		
		_canvas=New Canvas(New Image(_texture,_shader))		
		_material=New PbrMaterial( Color.White, 0.5, 0.5 )
		_material.ColorTexture=_texture
		_box=Model.CreateBox(New Boxf(-10,-10,-1,10,10,0 ),1,1,1,_material)
		_box.Move(0,10,0)
		
	End
	
	Method UpdateCanvas()
		_canvas.Clear(Color.Brown)
		_canvas.DrawText("Hello From Mojo3D",10,10)
		_canvas.DrawText("Frame = "+_frameCount,10,30)
		_canvas.Flush()
		_frameCount+=1
	End
		
	
	Method OnRender( canvas:Canvas ) Override
		
		UpdateCanvas()
		
		RequestRender()
'		_donut.Rotate( .2,.4,.6 )
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
