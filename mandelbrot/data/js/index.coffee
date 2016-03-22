canvas = null
ctx = null

canvas_over = null
ctx_over = null

mem_canvas = null
mem_ctx = null

window_width = null
window_height = null

jobs = []
jobs_complete = 0

worker_list = []
worker_num = 8

worker_redraw = null

is_running = false

xmin = null
xmax = null
ymin = null
ymax = null
dx = null
dy = null

img_data = []

get_color = null
color_custom_table = null

maxrad = 16
maxtry = 64

time_start = null
time_end = null

mouse_x = 0
mouse_y = 0

zoom_box = null
move_box = null

settype = 0

defo = ->
  xmin = -2.15
  xmax = 1.35
  ymin = -1.2
  ymax = 1.2
  maxtry = 64
  $("#color_selector").get(0).selectedIndex = 0
  $("#set_selector").get(0).selectedIndex = 0

crop = ->
  if ymax < ymin
    [ymax,ymin] = [ymin,ymax]
  if xmax < xmin
    [xmax,xmin] = [xmin,xmax]

  ratio = (ymax - ymin)/(xmax - xmin)
  win_ratio = window_height  / window_width
  if ratio == win_ratio
  else if ratio > win_ratio
    new_xlen = (ymax - ymin)/win_ratio
    cen_x = (xmax + xmin)/2
    xmin = cen_x - new_xlen/2
    xmax = cen_x + new_xlen/2
  else if ratio < win_ratio
    new_ylen = (xmax - xmin)*win_ratio
    cen_y = (ymax + ymin)/2
    ymin = cen_y - new_ylen/2
    ymax = cen_y + new_ylen/2

  dx = (xmax - xmin)/window_width
  dy = (ymax - ymin)/window_height

  $("#xmax").val(xmax)
  $("#xmin").val(xmin)
  $("#ymax").val(ymax)
  $("#ymin").val(ymin)
  null

callback = (msg) ->
  if not is_running
    return null
  worker = msg.currentTarget
  if jobs.length > 0
    j=jobs.pop()
    worker.postMessage(j)
  jobs_complete++
  img = ctx.createImageData(window_width,1)
  offset = 0
  i = 0
  while i < window_width
    color = get_color(msg.data.res[i])
    img.data[offset++] = color[0]
    img.data[offset++] = color[1]
    img.data[offset++] = color[2]
    img.data[offset++] = 255
    i++
  img_data[msg.data.canvas_y] = msg.data.res
  ctx.putImageData(img,0,msg.data.canvas_y)
  if jobs_complete == window_height
    is_running = false
    time_end = (new Date).getTime()
  null


callback_redraw = (hoge) ->
  y = 0
  while y < window_height
    x = 0
    offset = 0
    img = ctx.createImageData(window_width,window_height)
    while x < window_width
      color = get_color(img_data[y][x])
      img.data[offset++] = color[0]
      img.data[offset++] = color[1]
      img.data[offset++] = color[2]
      img.data[offset++] = 255
      x++
    ctx.putImageData(img, 0, y)
    y++
  null

color_grayscale = (data)->
  n = data[0]
  tr = data[1]
  ti = data[2]
  if n == maxtry
    return [0,0,0]

  c = Math.floor(256*n/maxtry)
  return [c,c,c]

color_grayscale_inv = (data) ->
  n = data[0]
  tr = data[1]
  ti = data[2]
  if n == maxtry
    return [0,0,0]
  r = n/maxtry
  c = Math.floor(256 - 256*r - 9*r*r)
  return [c,c,c]

color_hsv = (data) ->
  n = data[0]
  tr = data[1]
  ti = data[2]
  if n == maxtry
    return [0,0,0]
  return hsv_to_rgb(360.0*n/maxtry,1,1)

color_init_custom = ->
  i = 0
  width = colorpallet_gradiate.width
  pallet = colorpallet_gradiate_ctx.getImageData(0,0,width,1)
  offset = 0
  color_custom_table=[]
  while i<width
    color_custom_table[i]=[]
    color_custom_table[i][0] = pallet.data[offset++]
    color_custom_table[i][1] = pallet.data[offset++]
    color_custom_table[i][2] = pallet.data[offset++]
    i++
    offset++ #alfla
  null

color_custom = (data) ->
  # from gradiate pallet
  width = colorpallet_gradiate.width
  if data[0] == maxtry
    x=width-1
  else
    x = parseInt(width*data[0]/maxtry)
  return color_custom_table[x]

gen_workers = ->
  len = worker_list.length
  i=0
  while i < len
    worker_list[i].terminate()
    i++
  i=0
  while i<worker_num
    worker_list[i] = new Worker("js/worker.js")
    worker_list[i].worker_id = i
    i++
  null

gen_jobs = ->
  if is_running
    stop()
  i=0
  jobs_complete = 0
  while i < window_height
    jobs[i] = {
      canvas_y: (window_height - 1 -i)
      y: ymin+dy*i
      xmin: xmin
      dx: dx
      width: window_width
      maxrad: maxrad
      maxtry: maxtry
      settype: settype
    }
    i++
  null

start_jobs = ->
  time_start = (new Date).getTime()
  is_running = true
  i=0
  while i < worker_list.length
    j = jobs.pop()
    j.worker_id = i
    worker_list[i].postMessage(j)
    worker_list[i].onmessage = callback
    i++
  null

stop = ->
  is_running = false
  null

start = ->
  initialize()
  do_color()
  do_set()
  crop()
  reflesh()
  gen_jobs()
  gen_workers()
  start_jobs()
  null

reflesh = ->
  message()
  setTimeout(reflesh, 100)
  null

initialize = ->
  canvas=$('#canvas').get(0)
  canvas_over=$('#canvas_over').get(0)

  window_height = window.innerHeight
  window_width = window.innerWidth

  canvas.width = window_width
  canvas.height = window_height
  canvas_over.width = window_width
  canvas_over.height = window_height

  ctx = canvas.getContext("2d")
  ctx_over = canvas_over.getContext("2d")

  worker_redraw = new Worker("js/worker.js")
  worker_redraw.onmessage = callback_redraw

  $("#maxiter").val(maxtry)
  $("#worker").val(worker_num)

  img_data = []

message = ->
  float = (z) ->parseInt(z*100)/100
  if is_running
    $("#status").html("status: running <span class='glyphicon glyphicon-refresh' />")
    dt = ((new Date).getTime()-time_start)/1000
    $("#time").text("time:"+dt.toFixed(1)+"s")
  else
    $("#status").html("status: finished <span class='glyphicon glyphicon-ok' />")
  percent = 100*jobs_complete/window_height
  $("#progress-bar").css({width:percent+"%"})
  $("#mouse").text("mouse("+mouse_x+","+mouse_y+")  (x,y)=("+float(mouse_x*dx+xmin)+","+float(-mouse_y*dy+ymax)+")")
  null

do_color = ->
  flag_redraw = false
  color_scheme = $("#color_selector").get(0).selectedIndex
  if color_scheme == 0
    if get_color != color_grayscale
      $("body").css({"background":"#000"})
      get_color = color_grayscale
      flag_redraw = true
  else if color_scheme == 1
    if get_color != color_grayscale_inv
      $("body").css({"background":"#FFF"})
      get_color = color_grayscale_inv
      flag_redraw = true
  else if color_scheme == 2
    if get_color != color_hsv
      $("body").css({"background":"#F00"})
      get_color = color_hsv
      flag_redraw = true
  else if color_scheme == 3
    if get_color != color_custom
      $("body").css({"background":"#FFF"})
      get_color = color_custom
      flag_redraw = true
    color_init_custom()
    null

  if flag_redraw
    start()

do_set = ->
  tmp_settype = $("#set_selector").get(0).selectedIndex
  if settype != tmp_settype
    settype = tmp_settype
    start()

init_color = ->
  $(".selectpicker").selectpicker()
  $("#color_selector").change(
    ->
      do_color()
      null
  )
  get_color = color_grayscale
  $("body").css({"background":"#000"})

init_set = ->
  $("#set_selector").change(
    ->
      do_set()
      null
  )
  settype = 0

init_mouse = ->
  clear_over = ->
    ctx_over.lineWidth = 2
    ctx_over.clearRect(0,0,window_width, window_height)
    ctx_over.strokeStyle = "#aaa"
  stroke_over = ->
    if zoom_box != null
      ctx_over.strokeRect(zoom_box[0],zoom_box[1],zoom_box[2]-zoom_box[0],zoom_box[3]-zoom_box[1])
  $("#canvas_over").mousedown (even) ->
    if even.button == 0
      x=even.clientX
      y=even.clientY
      zoom_box=[x,y,x,y]
    else if even.button == 1
      move_box = [mouse_x,mouse_y]
      null
    null
  $("#canvas_over").mousemove (even) ->
    if even.button == 0
      mouse_x = even.clientX
      mouse_y = even.clientY
      clear_over()
      if zoom_box != null
        zoom_box[2] = mouse_x
        zoom_box[3] = mouse_y
      stroke_over()
    else if even.button == 1
      null
    null
  $("#canvas_over").mouseup (even) ->
    if zoom_box != null
      zoom_box[2] = even.clientX
      zoom_box[3] = even.clientY
      xmax =  zoom_box[2]*dx + xmin
      xmin =  zoom_box[0]*dx + xmin
      ymin = -zoom_box[1]*dy + ymax
      ymax = -zoom_box[3]*dy + ymax
    zoom_box = null
    if move_box != null
      xx = (xmax-xmin)*(mouse_x-move_box[0])/window_width
      yy = (ymax-ymin)*(mouse_y-move_box[1])/window_width
      xmax -= xx
      xmin -= xx
      ymax += yy
      ymin += yy
    move_box = null
    start()
    null
  null

init_buttom = ->
  $("#reset").click( ->
    defo()
    start()
    null
  )
  $("#redraw").click( ->
    if xmax != parseFloat($("#xmax").val())
      xmax = parseFloat($("#xmax").val())
    if xmin != parseFloat($("#xmin").val())
      xmin = parseFloat($("#xmin").val())
    if ymax != parseFloat($("#ymax").val())
      ymax = parseFloat($("#ymax").val())
    if ymin != parseFloat($("#ymin").val())
      ymin = parseFloat($("#ymin").val())
    if maxtry != parseInt($("#maxiter").val())
      maxtry = parseInt($("#maxiter").val())
    if worker_num != parseInt($("#worker").val())
      worker_num = parseInt($("#worker").val())
    start()
  )
  $("#png").click( ->
    window.location = canvas.toDataURL("image/png")
  )
  null
init_slidebar = ->
  $("#sidebarswitch").click(->
    $("#sidebar").toggleClass("sidebar_hide", 500)
    $("#sidebar-yaji").toggleClass("glyphicon-chevron-right")
    $("#sidebar-yaji").toggleClass("glyphicon-chevron-left")
  )


$(document).ready ->
  defo()
  init_color()
  init_set()
  init_buttom()
  init_mouse()
  init_slidebar()

  colorpallet_init()

  start()
  null

#################################

hsv_to_rgb = (h,s,v) ->
  h = h%360
  if v > 1.0
    v = 1.0
  hp = h/60.0
  c = v*s
  x=c*(1-Math.abs((hp%2)-1))
  rgb = [0,0,0]
  if hp<1
    rgb = [c,x,0]
  else if hp<2
    rgb = [x,c,0]
  else if hp<3
    rgb = [0,c,x]
  else if hp<4
    rgb = [0,x,c]
  else if hp<5
    rgb = [x,0,c]
  else if hp<6
    rgb = [c,0,x]
  m = v-c
  rgb[0] += m
  rgb[1] += m
  rgb[2] += m

  rgb[0] *= 255
  rgb[1] *= 255
  rgb[2] *= 255

  return rgb

rgb_to_hsv = (r,g,b) ->
  if r>1 or g>1 or b>1
    r/=255
    g/=255
    b/=255
  max = Math.max(r,g,b)
  min = Math.min(r,g,b)
  h=0
  s=0
  v=0
  if max == min
    h = 0
  else if max == r
    h = 60*(g-b)/(max-min)+0
  else if max == g
    h = 60*(b-r)/(max-min)+120
  else if max == b
    h = 60*(r-g)/(max-min)+240
  h%=360
  if max == 0
    s = 0
  else
    s = (max-min)/max
  v = max
  return [h,s,v]


#####colopallet
colorpallet_circle = null
colorpallet_triangle = null
colorpallet_point = null
colorpallet_circle_ctx = null
colorpallet_triangle_ctx = null
colorpallet_point_ctx = null
colorpallet_ctx = null
colorpallet_r = 100

colorpallet_h = 0
colorpallet_s = 0
colorpallet_v = 0

colorpallet_mouse = null
colorpallet_mouse_mode = null

colorpallet_gradiate = null
colorpallet_gradiate_ctx = null
colorpallet_gradiate_data = null
colorpallet_gradiate_selected = null
colorpallet_gradiate_editing = false

colorpallet_draw_triangle = ->
  h = Math.PI*colorpallet_h/180
  r= colorpallet_r
  colorpallet_triangle_ctx.save()
  colorpallet_triangle_ctx.translate(r,r)
  colorpallet_triangle_ctx.rotate(h)
  colorpallet_triangle_ctx.translate(-r,-r)
  colorpallet_triangle_ctx.clearRect(0,0,colorpallet_r*2,colorpallet_r*2)
  rad = 0
  x1 = Math.cos(rad*2)*r* 0.8+r
  y1 = Math.sin(rad*2)*r* 0.8+r
  rad+=Math.PI*1/3
  x2 = Math.cos(rad*2)*r* 0.8+r
  y2 = Math.sin(rad*2)*r* 0.8+r
  rad+=Math.PI*1/3
  x3 = Math.cos(rad*2)*r* 0.8+r
  y3 = Math.sin(rad*2)*r* 0.8+r
  colorpallet_triangle_ctx.beginPath()
  colorpallet_triangle_ctx.moveTo(x1,y1)
  colorpallet_triangle_ctx.lineTo(x2,y2)
  colorpallet_triangle_ctx.lineTo(x3,y3)
  colorpallet_triangle_ctx.closePath()
  colorpallet_triangle_ctx.clip()

  colorpallet_triangle_ctx.fillStyle = "#FFF"
  colorpallet_triangle_ctx.fillRect(0, 0, r*2, r*2)

  grad1 = colorpallet_triangle_ctx.createLinearGradient(0.6*r,r,1.8*r,r)
  c = hsv_to_rgb(colorpallet_h,1,1)
  s1="rgba("+parseInt(c[0])+","+parseInt(c[1])+","+parseInt(c[2])+","+1+")"
  s2="rgba("+parseInt(c[0])+","+parseInt(c[1])+","+parseInt(c[2])+","+0+")"
  grad1.addColorStop(0,s2)
  grad1.addColorStop(1,s1)
  colorpallet_triangle_ctx.fillStyle = grad1
  colorpallet_triangle_ctx.fillRect(0, 0, r*2, r*2)

  fr= 0.8*r
  grad2 = colorpallet_triangle_ctx.createLinearGradient(r-fr/2,r-fr*Math.sqrt(3)/2,r+fr/4,r+fr*Math.sqrt(3)/4)
  grad2.addColorStop(0,"rgba(0,0,0,1)")
  grad2.addColorStop(1,"rgba(0,0,0,0)")
  colorpallet_triangle_ctx.fillStyle = grad2
  colorpallet_triangle_ctx.fillRect(0, 0, r*2, r*2)

  colorpallet_triangle_ctx.restore()


colorpallet_init_circle = ->
  y = 0
  f = (i) -> i-colorpallet_r
  offset = 0
  img = colorpallet_circle_ctx.createImageData(2*colorpallet_r,2*colorpallet_r)
  while y < colorpallet_r*2
    x=0
    while x < colorpallet_r*2
      fx = f(x)
      fy = f(y)
      r = (fx*fx+fy*fy)/(colorpallet_r*colorpallet_r)
      if 0.64<r && r<1
        rad = -180*Math.atan2(fx,fy)/Math.PI+90
        if rad < 0
          rad += 360
        c = hsv_to_rgb(rad,1,1)
        img.data[offset++] = c[0]
        img.data[offset++] = c[1]
        img.data[offset++] = c[2]
        img.data[offset++] = 255
      else
        offset+=4
      x++
    y++
  colorpallet_circle_ctx.putImageData(img,0,0)
  null

colorpallet_draw_point = ->
  h = Math.PI*colorpallet_h/180
  r= colorpallet_r
  colorpallet_point_ctx.clearRect(0,0,colorpallet_r*2,colorpallet_r*2)
  colorpallet_point_ctx.save()
  colorpallet_point_ctx.translate(r,r)
  colorpallet_point_ctx.rotate(h)
  colorpallet_point_ctx.translate(-r,-r)
  colorpallet_point_ctx.strokeStyle = "#fff"
  colorpallet_point_ctx.lineWidth=2
  colorpallet_point_ctx.beginPath()
  colorpallet_point_ctx.moveTo(1.8*r,r)
  colorpallet_point_ctx.lineTo(2*r,r)
  colorpallet_point_ctx.stroke()
  colorpallet_point_ctx.restore()


colorpallet_click = (even) ->
  rect = even.target.getBoundingClientRect()
  x=even.clientX - rect.left
  y=even.clientY - rect.top
  f = (i) -> i-colorpallet_r
  fx=f(x)
  fy=f(y)
  r = (fx*fx+fy*fy)/(colorpallet_r*colorpallet_r)
  colorpallet_mouse = [x,y]
  rad = Math.atan2(fx,fy)
  if 0.64<r&&r<1 &&(colorpallet_mouse_mode == "circle" or colorpallet_mouse_mode == null)
    colorpallet_mouse_mode = "circle"
    rad = 180*rad/Math.PI-90
    if rad < 0
      rad += 360
    colorpallet_h = 360-rad
  else
    color = colorpallet_triangle_ctx.getImageData(x,y,1,1).data
    if color[3] != 0 &&(colorpallet_mouse_mode == "triangle" or colorpallet_mouse_mode == null)
      colorpallet_mouse_mode = "triangle"
      hsv = rgb_to_hsv(color[0],color[1],color[2])
      colorpallet_s = hsv[1]
      colorpallet_v = hsv[2]
  colorpallet_draw_triangle()
  colorpallet_draw_point()
  colorpallet_message()

colorpallet_dbclick = (e) ->
  rect = e.target.getBoundingClientRect()
  x = e.clientX - rect.left
  width = colorpallet_gradiate.width
  rad = x / width
  c = colorpallet_gradiate_ctx.getImageData(x,0,1,1).data
  console.log(c)
  colorpallet_gradiate_data.push([rad, c[0], c[1], c[2]])

  null

colorpallet_init_click = ->
  obj = colorpallet_point
  obj.onmousedown = (even) ->
    colorpallet_click(even)
    null
  obj.onmousemove = (even) ->
    if colorpallet_mouse != null
      colorpallet_click(even)
    null
  obj.onmouseup = (even) ->
    colorpallet_click(even)
    colorpallet_mouse = null
    colorpallet_mouse_mode = null
    null
  colorpallet_gradiate.ondblclick = (even) ->
    colorpallet_dbclick(even)
    null
  $("#colorpallet-delete").get(0).onclick = (e) ->
    idx = colorpallet_gradiate_selected
    console.log(idx)
    if 0 <= idx and idx < colorpallet_gradiate_data.length and colorpallet_gradiate_data.length > 2
      colorpallet_gradiate_data.splice(idx, 1)
      colorpallet_gradiate_selected = null
      colorpallet_draw_gradiate()
    null

  $("#colorpallet-ok").get(0).onclick = (e)->
    if 0 <= colorpallet_gradiate_selected < colorpallet_gradiate_data.length
      rgb = hsv_to_rgb(colorpallet_h,colorpallet_s,colorpallet_v)
      data = colorpallet_gradiate_data[colorpallet_gradiate_selected]
      data[1]=rgb[0]
      data[2]=rgb[1]
      data[3]=rgb[2]
      colorpallet_gradiate_data[colorpallet_gradiate_selected]=data
      colorpallet_draw_gradiate()
    null

colorpallet_draw_gradiate = ->
  width = colorpallet_gradiate.width
  height = colorpallet_gradiate.height
  colorpallet_gradiate_ctx.clearRect(0,0,width,height)
  grad = colorpallet_gradiate_ctx.createLinearGradient(0,0,width,0)
  i = 0
  len = colorpallet_gradiate_data.length
  while i < len
    d = colorpallet_gradiate_data[i]
    rgb = "rgb("+
        Math.floor(d[1])+","+
        Math.floor(d[2])+","+
        Math.floor(d[3])+")"
    grad.addColorStop(d[0],rgb)
    i++
  colorpallet_gradiate_ctx.fillStyle = grad
  colorpallet_gradiate_ctx.fillRect(0,0,width,height-10)

  i=0
  while i<len
    if i == colorpallet_gradiate_selected
      offset = 5
    else
      offset = 0
    colorpallet_gradiate_ctx.strokeStyle = "#FFF"
    d = colorpallet_gradiate_data[i]
    x = d[0]*width
    colorpallet_gradiate_ctx.lineWidth = 2
    colorpallet_gradiate_ctx.beginPath()
    colorpallet_gradiate_ctx.moveTo(x,10)
    colorpallet_gradiate_ctx.lineTo(x,height-5+offset)
    colorpallet_gradiate_ctx.stroke()
    colorpallet_gradiate_ctx.fillStyle = "#fff"
    colorpallet_gradiate_ctx.beginPath()
    colorpallet_gradiate_ctx.moveTo(x-3,height-5+offset)
    colorpallet_gradiate_ctx.lineTo(x,height-10+offset)
    colorpallet_gradiate_ctx.lineTo(x+3,height-5+offset)
    colorpallet_gradiate_ctx.lineTo(x-3,height-5+offset)
    colorpallet_gradiate_ctx.fill()
    i++
  null


colorpallet_init_gradiate = ->
  colorpallet_gradiate_data = []
  colorpallet_gradiate_data[0] = [0,0,0,0]
  colorpallet_gradiate_data[1] = [1,255,255,0]
  colorpallet_gradiate_data[2] = [0.2,255,0,0]
  colorpallet_gradiate_data[3] = [0.3,0,255,0]
  colorpallet_gradiate_data[4] = [0.5,0,0,255]
  colorpallet_draw_gradiate()
  null

colorpallet_gradiate_click =(e) ->
  rgb = colorpallet_gradiate_data[colorpallet_gradiate_selected]
  hsv = rgb_to_hsv(rgb[1],rgb[2],rgb[3])
  colorpallet_h = hsv[0]
  colorpallet_s = hsv[1]
  colorpallet_v = hsv[2]
  colorpallet_draw_triangle()
  colorpallet_draw_point()
  colorpallet_message()
  null

colorpallet_gradiate_drag =(e) ->
  rect = e.target.getBoundingClientRect()
  mx = e.clientX - rect.left
  rat = mx/colorpallet_gradiate.width
  if colorpallet_gradiate_selected != null and colorpallet_gradiate_selected < colorpallet_gradiate_data.length
    colorpallet_gradiate_data[colorpallet_gradiate_selected][0] = rat
  colorpallet_draw_gradiate()
  null

colorpallet_gradiate_on =(e) ->
  rect = e.target.getBoundingClientRect()
  mx = e.clientX - rect.left
  i = 0
  len = colorpallet_gradiate_data.length
  width = colorpallet_gradiate.width
  while i < len
    x = colorpallet_gradiate_data[i][0]*width
    if x-4 < mx && mx<x+4
      colorpallet_gradiate_selected = i
      colorpallet_gradiate.style.cursor = "pointer"
      break
    else
      if not colorpallet_gradiate_editing
        colorpallet_gradiate_selected = null
      colorpallet_gradiate.style.cursor = "default"
    i++
  colorpallet_draw_gradiate()
  null

colorpallet_gradiate_init_click = ->
  obj = colorpallet_gradiate
  is_on = false
  obj.onmousedown = (even) ->
    is_on = true
    colorpallet_gradiate_drag(even)
    null
  obj.onmouseup = (even) ->
    is_on = false
    colorpallet_draw_gradiate()
    null
  obj.onclick = (even) ->
    colorpallet_gradiate_editing = true
    colorpallet_gradiate_click(even)
  obj.onmousemove = (even) ->
    if is_on
      colorpallet_gradiate_drag(even)
    else
      colorpallet_gradiate_on(even)
    null


colorpallet_init = ->
  colorpallet_triangle = $("#colorpallet-triangle").get(0)
  colorpallet_circle = $("#colorpallet-circle").get(0)
  colorpallet_point = $("#colorpallet-point").get(0)
  colorpallet_circle.width = colorpallet_r*2
  colorpallet_circle.height = colorpallet_r*2
  colorpallet_point.width = colorpallet_r*2
  colorpallet_point.height = colorpallet_r*2
  colorpallet_triangle.width = colorpallet_r*2
  colorpallet_triangle.height = colorpallet_r*2
  colorpallet_circle_ctx = colorpallet_circle.getContext("2d")
  colorpallet_point_ctx = colorpallet_point.getContext("2d")
  colorpallet_triangle_ctx = colorpallet_triangle.getContext("2d")

  colorpallet_gradiate = $("#colorpallet-gradiate").get(0)
  colorpallet_gradiate_ctx = colorpallet_gradiate.getContext("2d")
  colorpallet_gradiate.width = 280
  colorpallet_gradiate.height = 30

  colorpallet_init_circle()
  colorpallet_init_click()
  colorpallet_init_gradiate()
  colorpallet_gradiate_init_click()
  colorpallet_draw_triangle()
  colorpallet_draw_point()
  colorpallet_message()
  null

colorpallet_message = ->
  $("#colorpallet-h").val(colorpallet_h)
  $("#colorpallet-s").val(colorpallet_s)
  $("#colorpallet-v").val(colorpallet_v)

  c=hsv_to_rgb(colorpallet_h,colorpallet_s,colorpallet_v)
  c[0]=Math.floor(c[0]).toString(16);c[1]=Math.floor(c[1]).toString(16);c[2]=Math.floor(c[2]).toString(16)
  i=0
  while i<3
    if c[i].length == 1
      c[i]='0'+c[i]
    i++
  $("#colorpallet-rgb").val("#"+c[0]+c[1]+c[2])