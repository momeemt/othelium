import std/[
  sets
]

type
  Disc* = object
    row, col: int
  
  Discs* = HashSet[Disc]
  
  DiscIndex* = range[0..63]

  TurnStatus* {.pure.} = enum
    Black, White 

  Board* = object
    white_discs*: Discs
    black_discs*: Discs
    current_turn*: TurnStatus

const SearchingVectors = toHashSet([
  (0, 1), (0, -1), (1, 0), (-1, 0),
  (1, 1), (1, -1), (-1, 1), (-1, -1)
])

func initBoard*: Board =
  ## ボードを作成します
  result = Board()
  result.current_turn = Black

func initDisc* (row, col: range[0..7]): Disc =
  ## `row`と`col`からDiscを作成します
  result = Disc(row: row, col: col)

func initDisc* (index: DiscIndex): Disc =
  result = Disc(row: index mod 8, col: index div 8)

func initDiscs* (discs: varargs[Disc]): Discs =
  result = toHashSet(discs)

func `!`* (turn_status: TurnStatus): TurnStatus =
  ## `TurnStatus`を変更します
  if turn_status == Black:
    result = White
  else:
    result = Black

func changeTurn* (board: Board): Board =
  ## `board`の現在のターンを変更します
  result = board
  result.current_turn = !board.current_turn

func count* (board: Board): int =
  result = board.white_discs.len + board.black_discs.len

func `^`* (disc: Disc): DiscIndex =
  ## `Disc`型のオブジェクトを0~63のインデックス番号に変換します
  result = disc.col * 8 + disc.row

func `@`* (discs: Discs): seq[Disc] =
  for disc in discs:
    result.add disc

func myDiscs* (board: Board): Discs =
  ## 現在のターンから見て自分のディスクを返します
  if board.current_turn == Black:
    result = board.black_discs
  else:
    result = board.white_discs

proc `myDiscs=`* (board: var Board, discs: Discs) =
  ## 現在のターンから見て自分のディスクを`discs`に変更します
  if board.current_turn == Black:
    board.black_discs = discs
  else:
    board.white_discs = discs

func opponentsDiscs* (board: Board): Discs =
  ## 現在のターンから見て相手のディスクを返します
  result = case board.current_turn
           of Black: board.white_discs
           of White: board.black_discs

proc `opponentsDiscs=`* (board: var Board, discs: Discs) =
  ## 現在のターンから見て相手のディスクを`discs`に変更します
  case board.current_turn
  of Black: board.white_discs = discs
  of White: board.black_discs = discs

func valid (disc: Disc): bool =
  ## `disc`が64マスに正しく設定されているかどうかを調べます
  result = 0 <= disc.row and disc.row <= 7 and
           0 <= disc.col and disc.col <= 7

proc `+=` (disc: var Disc, delta: tuple[dx, dy: int]) =
  ## `disc`を指定したベクトル方向に進めます
  disc.row += delta.dy
  disc.col += delta.dx

iterator searchBoard* (disc: Disc, dy, dx: int): Disc =
  ## `disc`を基準に指定したベクトルに向けて探索します
  var disc = disc
  disc += (dx, dy)
  while disc.valid:
    yield disc
    disc += (dx, dy)

func canDrop* (board: Board, disc: Disc): bool =
  ## `disc`が`board`に設置可能かどうかを返します
  if disc in board.black_discs or disc in board.white_discs:
    return false
  
  for (row, col) in SearchingVectors:
    var passed_opponent = false
    for searching_disc in searchBoard(disc, row, col):
      if searching_disc in board.opponentsDiscs:
        passed_opponent = true
      elif passed_opponent and searching_disc in board.myDiscs:
        return true
      else:
        break

func singleDrop (board: Board, disc: Disc): Board =
  ## `disc`を設置したBoardオブジェクトを返します
  result = board
  if result.current_turn == Black:
    result.black_discs.incl disc
  else:
    result.white_discs.incl disc

func drop* (board: Board, disc: Disc): Board =
  ## `disc`を指した場合の変化を含めたBoardオブジェクトを返します
  result = board
  for (row, col) in SearchingVectors:
    var
      passed_opponent = false
      discs_possible_to_add: Discs
    for searching_disc in searchBoard(disc, row, col):
      if searching_disc in result.opponentsDiscs:
        passed_opponent = true
        discs_possible_to_add.incl searching_disc
      elif passed_opponent and (searching_disc in result.myDiscs):
        result.myDiscs = result.myDiscs + discs_possible_to_add
        result.opponentsDiscs = result.opponentsDiscs - discs_possible_to_add
        break
      else:
        break
  result = result.singleDrop(disc)

func discsPossibleToDrop* (board: Board): Discs =
  ## 指すことのできるDisc一覧を返します
  for row in 0 ..< 8:
    for col in 0 ..< 8:
      let disc = initDisc(row, col)
      if board.canDrop(disc):
        result.incl disc

func finished* (board: Board): bool =
  let
    myDiscsPossibleToDrop = board.discsPossibleToDrop()
    opponentsDiscsPossibleToDrop = board.changeTurn().discsPossibleToDrop()
  result = board.count == 64 or (myDiscsPossibleToDrop.len == 0 and opponentsDiscsPossibleToDrop.len == 0)
