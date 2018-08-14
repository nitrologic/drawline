Class HyperbolicContext Extends SmoothContext

	' hyperbolic 1/x

	Method Zoom(z:Float) Override
		Local zz:=z	'Pow(z,1/power)
		target.Scale(zz,zz)
	End

	Method Plot(xy:XY,r:Radius) Override
		Local rr:=r'1000.0/r
		Local d:=xy.Distance(origin)
		If d>0
			d=0.01/(d*d)
		Else
			d=1
		Endif
		Super.Plot(xy*d,r)
	End

End

	Method VLin(quad:Quad) Override
		Line(quad.TopLeft,quad.BottomLeft,quad.Width)
	End

	Method HLin(quad:Quad) Override
		Line(quad.TopLeft,quad.TopRight,quad.Height)
	End

	Method VLin(quad:Quad) Virtual
		target.DrawRect(quad,circle,vrect3)
	End

	Method HLin(quad:Quad) Virtual
		target.DrawRect(quad,circle,hrect3)
	End


	Method DrawGrid(w:Int,h:Int)
		Local thick:=Abs(zoom)
		Local g:=grid*thick*16

		Local wide:Int=1+w/g
		Local hi:Int=1+h/g

		Local oy:=((org.Y Mod g)-g)Mod g
		Local ox:=((org.X Mod g)-g)Mod g
		
		Local iy:Int=math.Floor(-org.y/g)
		For Local y:=oy To h Step g						
			Local th:=thick * ((iy&3) ? 1 Else 2)
			Local rect:=New Rectf(-w,y-th,w,y+th)
'			canvas.DrawRect(rect)
'			canvas.DrawRect(rect,circle,hrect2)
			context.HLin(rect)
			iy+=1
		Next
	
		Local ix:Int=math.Floor(-org.x/g)
		For Local x:=ox To w Step g
			Local th:=thick * ((ix&3) ? 1 Else 2)
			Local rect:=New Rectf(x-th,h,x+th,h)
'			canvas.DrawRect(rect)
'			canvas.DrawRect(rect,circle,vrect2)
			context.VLin(rect)
			ix+=1
		Next
	End
