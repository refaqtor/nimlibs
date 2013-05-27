import fowltek/entitty, fowltek/sdl2

import fowltek/vector_math
type TVector2f* = TVector2[float]


proc debugSTR* (result: var seq[string]) {.multicast.}
proc debugSTR* (entity: PEntity): seq[string] =
  newseq result, 0
  entity.debugStr result
template debug_str_impl(ty): stmt {.immediate.}=
  msg_impl(ty, debugSTR) do (result: var seq[string]):
    result.add("$1: $2".format(componentInfo(ty).name, $ entity[ty]))


proc update* (dt: float) {.multicast.}
proc getPos* : TVector2f {.unicast.}
proc draw* (R: PRenderer) {.unicast.}


proc `$`* (some: TVector2f): string = "($1, $2)" % [formatFloat(some.x, ffDecimal, 4),
  formatFloat(some.y, ffDecimal, 4) ]




type
  Pos* = TVector2f
msg_impl(Pos, get_pos) do -> TVector2f: 
  result = entity[Pos]
debug_str_impl Pos

type
  Vel* = object
    v*: TVector2f

msg_impl(Vel, update) do (dt: float):
  entity[Pos] += entity[Vel].v * dt

msg_impl(Vel, debugSTR) do(result:var seq[string]):
  result.add "Vel: $1" % $entity[Vel].v
from fowltek/sdl2/spritecache import newSpriteCache, get, PSprite, setImageRoot

type
  SpriteInst* = object
    sprite*: PSprite
    rect*: TRect
SpriteInst.requiresComponent Pos

msg_impl(SpriteInst, draw) do (R: PRenderer):
  #something
  var dest = entity[SpriteInst].rect
  let p = entity[Pos].addr
  dest.x = p.x.cint
  dest.y = p.y.cint
  R.copy entity[SpriteInst].sprite.tex, 
    entity[SpriteInst].rect.addr, dest.addr  


var imageCache* = newSpriteCache(64)
proc setImageRoot* (dir: string) {.inline.} = 
  imagecache.setImageRoot(dir)

proc loadSprite* (s: var SpriteInst, R: PRenderer; file: string) =
  s.sprite = imagecache.get(R, file)
  s.rect = s.sprite.defaultRect


type
  TFrame* = tuple[col: int, time: float] 
  SimpleAnim* = object
    frames: seq[TFrame]
    curFrame: int
    timer: float
SimpleAnim.requiresComponent SpriteInst


proc loadSimpleAnim* (ent: PEntity; R: PRenderer; file: string) =
  ent[SpriteInst].loadSprite R, file
  ent[SimpleAnim].timer = 0.2
  newSeq ent[SimpleAnim].frames, ent[SpriteInst].sprite.cols

  for i in 0 .. <ent[SpriteInst].sprite.cols:
    ent[SimpleAnim].frames[i].col = i
    ent[SimpleAnim].frames[i].time = 0.2

msg_impl(SimpleAnim, update) do (dt: float): 
  entity[SimpleAnim].timer -= dt
  if entity[SimpleAnim].timer <= 0:
    let frameIndex = (entity[SimpleAnim].curFrame+1) mod entity[SimpleAnim].frames.len
    entity[SimpleAnim].curFrame = frameIndex
    entity[SimpleAnim].timer = entity[SimpleAnim].frames[frameIndex].time
    entity[SpriteInst].rect.x =cint(
      entity[SpriteInst].rect.w * entity[SimpleAnim].frames[frameIndex].col )



type
  ToroidalBounds* = object
    rect*: TRect
ToroidalBounds.requiresComponent pos

proc right* (some: TRect): cint = some.x + some.w
proc bottom*(some: TRect): cint = some.y + some.h

msg_impl(ToroidalBounds, update) do (dt: float) :
  let p = entity[Pos].addr
  if p.x.cint < entity[ToroidalBounds].rect.x:
    p.x = entity[ToroidalBounds].rect.right.float
  elif p.x.cint > entity[ToroidalBounds].rect.right:
    p.x = entity[ToroidalBounds].rect.x.float
  if p.y.cint < entity[ToroidalBounds].rect.y:
    p.y = entity[ToroidalBounds].rect.bottom.float
  elif p.y.cint > entity[ToroidalBounds].rect.bottom:
    p.y = entity[ToroidalBounds].rect.y.float





