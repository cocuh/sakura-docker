"use strict"

mandelbro = (cr, ci, maxrad, maxtry) ->
  zr=0; zi=0; tr=0; ti=0
  n=0

  while n<maxtry and (tr+ti)<=maxrad
    zi=2*zr*zi+ci
    zr=tr-ti+cr
    tr=zr*zr
    ti=zi*zi
    n++

  i=0
  while i<3
    zi=2*zr*zi+ci
    zr=tr-ti+cr
    tr=zr*zr
    ti=zi*zi
    i++
  return [n,tr,ti]

burning = (cr, ci, maxrad, maxtry) ->
  zr=0; zi=0; tr=0; ti=0
  n=0

  while n<maxtry and (tr+ti)<=maxrad
    zi=2*Math.abs(zr)*Math.abs(zi)-ci
    zr=tr-ti+cr
    tr=zr*zr
    ti=zi*zi
    n++

  i=0
  while i<3
    zi=2*zr*zi+ci
    zr=tr-ti+cr
    tr=zr*zr
    ti=zi*zi
    i++
  return [n,tr,ti]

@onmessage = (inp) ->
  d = inp.data

  y = d.y
  xmin = d.xmin
  dx = d.dx
  width = d.width
  maxrad = d.maxrad
  maxtry = d.maxtry

  settype = d.settype
  switch settype
    when 0
      calc = mandelbro
    when 1
      calc = burning
    else
      calc = mandelbro


  n=0
  res = []
  while n < width
    res[n] = calc(xmin+dx*n,y,maxrad,maxtry)
    n++
  postMessage
    canvas_y: d.canvas_y
    worker_id: d.worker_id
    y: d.y
    res: res

