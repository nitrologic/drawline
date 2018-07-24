#Import "<std>"
#Import "<mojo>"

Using std..
Using mojo..

Alias XY:Vec2<Double>
Alias Quad:Rectf
Alias Radius:Double

Alias VectorFont:Map<Int,Int[]>

Class SmoothContext
	
	Field circle:=AlphaRing()
		
	Field vrect3:=New Recti(256-64,256,256+64,256)
	Field hrect3:=New Recti(256,256-64,256,256+64)
	
	Field target:Canvas	
	Field font:VectorFont

	Field tube:Tube
	Field foreground:UInt
	
	Method BeginPaint(canvas:Canvas,vectorfont:VectorFont)
		target=canvas
		font=vectorfont
		target.BlendMode=BlendMode.Alpha
		target.Translate(0,0)		
		tube=New Tube
	End
	
	Method Foreground(color:Color)
		Local c:=color.ToARGB()
		c=(c Shl 8)|((c Shr 24)&$ff)
		Local rgba:=((c&$ff)Shl 24)|((c&$ff00)Shl 8)|((c Shr 8)&$ff00)|((c Shr 24)&$ff)
		foreground=rgba
	End
	
	Method VLin(quad:Quad)
		target.DrawRect(quad,circle,vrect3)
	End

	Method HLin(quad:Quad)
		target.DrawRect(quad,circle,hrect3)
	End
	
	Method Origin(xy:XY)
		target.Translate(xy.X,xy.Y)
	End
	
	Method Zoom(z:Float)
		target.Scale(z,z)
	End
	
	Method Plot(xy:XY,r:Radius)
		Local quad:=New Quad(xy.X-r,xy.y-r,xy.X+r,xy.y+r)
		target.DrawRect(quad,circle)
	End

	Method Text(xy:XY,r:Radius,text:String)
		Local cursor:=xy
		For Local t:Int=Eachin text
			Local glyph:=font[t]			
'			Print "t="+t+" g="+glyph.Length			
			Local n:Int=glyph.Length/4
			Local ab:=New XY[2]
			For Local i:=0 Until n
				ab[0].X=glyph[i*4+0]+cursor.X
				ab[0].Y=glyph[i*4+1]+cursor.Y
				ab[1].X=glyph[i*4+2]+cursor.X
				ab[1].Y=glyph[i*4+3]+cursor.Y
				Line(ab[0],ab[1],r)
			Next
			cursor.X+=8
		Next
	End

	Method Line(p0:XY,p1:XY,r0:Radius)
		tube.start(p0,r0,foreground)
		tube.move(p1)
		tube.finish(target,circle)
	End

'	Method Draw(shape:Shape)		
'	End
	
	Method EndPaint()
		target=Null
	End
End	

Function AlphaRing:Image()
	Local d:=512
	Local r:=32
	Local pix:=New Pixmap(d,d,PixelFormat.RGBA8)
	For Local y:=0 Until d
		For Local x:=0 Until d
			Local dx:=x-d/2
			Local dy:=y-d/2
			Local rr:Double=(dx*dx+dy*dy)-r*r			
			Local a:=0
			If rr<0 
				a=255
			Elseif rr<512
				a=11.2*Sqrt(512-rr)
			Endif
			Local p:=pix.PixelPtr(x,y)
			p[0]=a
			p[1]=a
			p[2]=a
			p[3]=a
		Next
	Next
'	SavePixmap(pix,"C:/nitrologic/test.png")
'	Print "filter"+Int(TextureFlags.FilterMipmap)
	Local texture:=New Texture(pix,TextureFlags.FilterMipmap)
	Return New Image(texture)
End

Class Tube
	Const MaxCount:=64
	
	Field verts:=New Float[MaxCount*4]
	Field uv:=New Float[MaxCount*4]
	Field colors:=New UInt[MaxCount*2]
	Field indices:=New Int[MaxCount*6]
	
	Field pos:XY
	Field pos1:XY
	Field gutter:Double
	Field thick:Double
	Field count:Int
	Field color:UInt
	
	Method New()
'		DebugStop()
		For Local i:=0 Until MaxCount
			indices[i*6+0]=i*2+0
			indices[i*6+1]=i*2+2
			indices[i*6+2]=i*2+1
			indices[i*6+3]=i*2+1			
			indices[i*6+4]=i*2+2			
			indices[i*6+5]=i*2+3			
		Next
	End
	
	Method start(xy:XY,width:Double,foreground:UInt)
		pos=xy
		thick=width
		gutter=0.25
		count=1
		color=foreground
	End

	Method move(xy:XY)
		
		Local dir:=(xy-pos).Normalize()

		If count=1
			uv[0]=0.0+gutter
			uv[1]=0.0+gutter
			uv[2]=0.0+gutter
			uv[3]=1.0-gutter

			verts[0]=pos.X+(dir.Y-dir.X)*thick
			verts[1]=pos.Y-(dir.X+dir.Y)*thick
			verts[2]=pos.X-(dir.Y+dir.X)*thick
			verts[3]=pos.Y+(dir.X-dir.Y)*thick	

			colors[0]=color
			colors[1]=color

			uv[4]=0.5
			uv[5]=0.0+gutter
			uv[6]=0.5
			uv[7]=1.0-gutter
			
			verts[4]=pos.X+dir.Y*thick
			verts[5]=pos.Y-dir.X*thick
			verts[6]=pos.X-dir.Y*thick
			verts[7]=pos.Y+dir.X*thick

			colors[2]=color
			colors[3]=color

			count=2
		Endif

		uv[count*4+0]=0.5
		uv[count*4+1]=0.0+gutter
		uv[count*4+2]=0.5
		uv[count*4+3]=1.0-gutter

		verts[count*4+0]=xy.X+dir.Y*thick
		verts[count*4+1]=xy.Y-dir.X*thick
		verts[count*4+2]=xy.X-dir.Y*thick
		verts[count*4+3]=xy.Y+dir.X*thick
		
		colors[count*2+0]=color
		colors[count*2+1]=color
		
		pos1=pos
		pos=xy		
		count+=1
	End
	
	Method finish(canvas:Canvas,circle:Image)

		Local dir:=(pos-pos1).Normalize()

		verts[count*4+0]=pos.X+(dir.Y+dir.X)*thick
		verts[count*4+1]=pos.Y-(dir.X-dir.Y)*thick
		verts[count*4+2]=pos.X-(dir.Y-dir.X)*thick
		verts[count*4+3]=pos.Y+(dir.X+dir.Y)*thick

		uv[count*4+0]=1.0-gutter
		uv[count*4+1]=0.0+gutter
		uv[count*4+2]=1.0-gutter
		uv[count*4+3]=1.0-gutter		

		colors[count*2+0]=color
		colors[count*2+1]=color

		Local order:=3
		Local primCount:=count*2

		Local verts0:=Varptr verts[0]
		Local uv0:=Varptr uv[0]
		Local indices0:=Varptr indices[0]
		Local colors0:=Varptr colors[0]
				
		canvas.DrawPrimitives(order,primCount,verts0,8,uv0,8,colors0,4,circle,indices0)
	End
End

