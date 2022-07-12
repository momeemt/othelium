import nimx/[
  window,
  text_field,
  collection_view,
  timer,
  button
]
import std/[sets, os, random]

type
  PlayerTurn {.pure.} = enum
    Black, White
  
  Board = object
    white_discs: HashSet[int]
    black_discs: HashSet[int]
    current_turn: PlayerTurn

func init (_: typedesc[Board]): Board =
  result = Board()
  result.white_discs = toHashSet([27, 36])
  result.black_discs = toHashSet([28, 35])
  result.current_turn = White

func turn (board: Board): Board =
  result = board
  result.current_turn = case result.current_turn
                        of White: Black
                        of Black: White

func toCoord (disc_number: int): (int, int) =
  result = (disc_number mod 8, disc_number div 8)

func toDiscNumber (row, col: int): int =
  result = col * 8 + row

func myDiscs (board: Board): HashSet[int] =
  result = case board.current_turn
           of Black: board.black_discs
           of White: board.white_discs

proc `myDiscs=` (board: var Board, discs: HashSet[int]) =
  case board.current_turn
  of Black: board.black_discs = discs
  of White: board.white_discs = discs

func opponentsDiscs (board: Board): HashSet[int] =
  result = case board.current_turn
           of Black: board.white_discs
           of White: board.black_discs

proc `opponentsDiscs=` (board: var Board, discs: HashSet[int]) =
  case board.current_turn
  of Black: board.white_discs = discs
  of White: board.black_discs = discs

func searchUpward (board: Board, disc_number: int): bool =
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  for seraching_col in countdown(col-1, 0):
    let searching_disc_number = toDiscNumber(row, seraching_col)
    if searching_disc_number in board.opponentsDiscs:
      passed_opponent = true
    elif passed_opponent and searching_disc_number in board.myDiscs:
      return true
    else:
      break

proc searchDownwards (board: Board, disc_number: int): bool =
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  for seraching_col in countup(col+1, 7):
    let searching_disc_number = toDiscNumber(row, seraching_col)
    if searching_disc_number in board.opponentsDiscs:
      passed_opponent = true
    elif passed_opponent and searching_disc_number in board.myDiscs:
      return true
    else:
      break

proc searchLeft (board: Board, disc_number: int): bool =
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  for seraching_row in countdown(row-1, 0):
    let searching_disc_number = toDiscNumber(seraching_row, col)
    if searching_disc_number in board.opponentsDiscs:
      passed_opponent = true
    elif passed_opponent and searching_disc_number in board.myDiscs:
      return true
    else:
      break

proc searchRight (board: Board, disc_number: int): bool =
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  for seraching_row in countup(row+1, 7):
    let searching_disc_number = toDiscNumber(seraching_row, col)
    if searching_disc_number in board.opponentsDiscs:
      passed_opponent = true
    elif passed_opponent and searching_disc_number in board.myDiscs:
      return true
    else:
      break

proc searchLowerRight (board: Board, disc_number: int): bool =
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  var min_index = min(row, col)
  for index in 1..min_index:
    let searching_disc_number = toDiscNumber(row-index, col-index)
    if searching_disc_number in board.opponentsDiscs:
      passed_opponent = true
    elif passed_opponent and searching_disc_number in board.myDiscs:
      return true
    else:
      break

proc searchUpperLeft (board: Board, disc_number: int): bool =
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  var min_index = min(7-row, 7-col)
  for index in 1..min_index:
    let searching_disc_number = toDiscNumber(row+index, col+index)
    if searching_disc_number in board.opponentsDiscs:
      passed_opponent = true
    elif passed_opponent and searching_disc_number in board.myDiscs:
      return true
    else:
      break

proc searchLowerLeft (board: Board, disc_number: int): bool =
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  var min_index = min(row, 7-col)
  for index in 1..min_index:
    let searching_disc_number = toDiscNumber(row-index, col+index)
    if searching_disc_number in board.opponentsDiscs:
      passed_opponent = true
    elif passed_opponent and searching_disc_number in board.myDiscs:
      return true
    else:
      break

proc searchUpperRight (board: Board, disc_number: int): bool =
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  var min_index = min(7-row, col)
  for index in 1..min_index:
    let searching_disc_number = toDiscNumber(row+index, col-index)
    if searching_disc_number in board.opponentsDiscs:
      passed_opponent = true
    elif passed_opponent and searching_disc_number in board.myDiscs:
      return true
    else:
      break

proc canPlaceDisc (board: Board, target_disc_number: int): bool =
  if target_disc_number in board.black_discs or target_disc_number in board.white_discs:
    return false

  result = board.searchUpward(target_disc_number) or
           board.searchDownwards(target_disc_number) or
           board.searchLeft(target_disc_number) or
           board.searchRight(target_disc_number) or
           board.searchLowerRight(target_disc_number) or
           board.searchUpperLeft(target_disc_number) or
           board.searchLowerLeft(target_disc_number) or
           board.searchUpperRight(target_disc_number)

func putUpward (board: Board, disc_number: int): Board =
  result = board
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  var addition_disc: HashSet[int]
  for disc_number in countdown(col-1, 0):
    let searching_disc_number = toDiscNumber(row, disc_number)
    if searching_disc_number in result.opponentsDiscs:
      passed_opponent = true
      addition_disc.incl searching_disc_number
    elif passed_opponent and searching_disc_number in result.myDiscs:
      result.myDiscs = result.myDiscs + addition_disc
      result.opponentsDiscs = result.opponentsDiscs - addition_disc
    else:
      break

func putDownwards (board: Board, disc_number: int): Board =
  result = board
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  var addition_disc: HashSet[int]
  for disc_number in countup(col+1, 7):
    let searching_disc_number = toDiscNumber(row, disc_number)
    if searching_disc_number in result.opponentsDiscs:
      passed_opponent = true
      addition_disc.incl searching_disc_number
    elif passed_opponent and searching_disc_number in result.myDiscs:
      result.myDiscs = result.myDiscs + addition_disc
      result.opponentsDiscs = result.opponentsDiscs - addition_disc
    else:
      break

func putLeft (board: Board, disc_number: int): Board =
  result = board
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  var addition_disc: HashSet[int]
  for disc_number in countdown(row-1, 0):
    let searching_disc_number = toDiscNumber(disc_number, col)
    if searching_disc_number in result.opponentsDiscs:
      passed_opponent = true
      addition_disc.incl searching_disc_number
    elif passed_opponent and searching_disc_number in result.myDiscs:
      result.myDiscs = result.myDiscs + addition_disc
      result.opponentsDiscs = result.opponentsDiscs - addition_disc
    else:
      break

func putRight (board: Board, disc_number: int): Board =
  result = board
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  var addition_disc: HashSet[int]
  for disc_number in countup(row+1, 7):
    let searching_disc_number = toDiscNumber(disc_number, col)
    if searching_disc_number in result.opponentsDiscs:
      passed_opponent = true
      addition_disc.incl searching_disc_number
    elif passed_opponent and searching_disc_number in result.myDiscs:
      result.myDiscs = result.myDiscs + addition_disc
      result.opponentsDiscs = result.opponentsDiscs - addition_disc
    else:
      break

func putLowerRight (board: Board, disc_number: int): Board =
  result = board
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  var addition_disc: HashSet[int]
  let min_index = min(row, col)
  for index in 1..min_index:
    let searching_disc_number = toDiscNumber(row-index, col-index)
    if searching_disc_number in result.opponentsDiscs:
      passed_opponent = true
      addition_disc.incl searching_disc_number
    elif passed_opponent and searching_disc_number in result.myDiscs:
      result.myDiscs = result.myDiscs + addition_disc
      result.opponentsDiscs = result.opponentsDiscs - addition_disc
    else:
      break

func putUpperLeft (board: Board, disc_number: int): Board =
  result = board
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  var addition_disc: HashSet[int]
  let min_index = min(7-row, 7-col)
  for index in 1..min_index:
    let searching_disc_number = toDiscNumber(row+index, col+index)
    if searching_disc_number in result.opponentsDiscs:
      passed_opponent = true
      addition_disc.incl searching_disc_number
    elif passed_opponent and searching_disc_number in result.myDiscs:
      result.myDiscs = result.myDiscs + addition_disc
      result.opponentsDiscs = result.opponentsDiscs - addition_disc
    else:
      break

func putLowerLeft (board: Board, disc_number: int): Board =
  result = board
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  var addition_disc: HashSet[int]
  let min_index = min(row, 7-col)
  for index in 1..min_index:
    let searching_disc_number = toDiscNumber(row-index, col+index)
    if searching_disc_number in result.opponentsDiscs:
      passed_opponent = true
      addition_disc.incl searching_disc_number
    elif passed_opponent and searching_disc_number in result.myDiscs:
      result.myDiscs = result.myDiscs + addition_disc
      result.opponentsDiscs = result.opponentsDiscs - addition_disc
    else:
      break

func putUpperRight (board: Board, disc_number: int): Board =
  result = board
  let (row, col) = disc_number.toCoord()
  var passed_opponent = false
  var addition_disc: HashSet[int]
  let min_index =min(7-row, col)
  for index in 1..min_index:
    let searching_disc_number = toDiscNumber(row+index, col-index)
    if searching_disc_number in result.opponentsDiscs:
      passed_opponent = true
      addition_disc.incl searching_disc_number
    elif passed_opponent and searching_disc_number in result.myDiscs:
      result.myDiscs = result.myDiscs + addition_disc
      result.opponentsDiscs = result.opponentsDiscs - addition_disc
    else:
      break

func singlePut (board: Board, disc_number: int): Board =
  result = board
  case result.current_turn
  of White: result.white_discs.incl disc_number
  of Black: result.black_discs.incl disc_number

func put (board: Board, disc_number: int): Board =
  result = board.putUpward(disc_number)
                .putDownwards(disc_number)
                .putLeft(disc_number)
                .putRight(disc_number)
                .putLowerRight(disc_number)
                .putUpperLeft(disc_number)
                .putLowerLeft(disc_number)
                .putUpperRight(disc_number)
                .singlePut(disc_number)

func possiblePutList (board: Board): seq[int] =
  for disc_number in 0 ..< 64:
    if board.canPlaceDisc(disc_number):
      result.add disc_number

var
  board = Board.init()
  my_rnd = initRand(2003)

proc startApp() =
  var wnd = newWindow(newRect(40, 40, 419, 419))

  let collectionView = newCollectionView(newRect(0, 0, 419, 419), newSize(50, 50), LayoutDirection.LeftToRight)
  collectionView.numberOfItems = proc(): int =
    return 64
  collectionView.viewForItem = proc(i: int): View =
    var button = newButton(newRect(0, 0, 100, 100))
    button.onAction(proc () =
      if board.canPlaceDisc(i):
        board = board.put(i).turn()
        collectionView.updateLayout()
    )

    if board.canPlaceDisc(i):
      button.backgroundColor = newColor(0.0, 0.0, 1.0, 1.0)
    else:
      button.backgroundColor = newColor(0.0, 1.0, 0.0, 1.0)
    result = button
    
    var circle = newView(newRect(15, 15, 20, 20))
    if i in board.white_discs:
      circle.backgroundColor = newColor(1.0, 1.0, 1.0, 1.0)
    elif i in board.black_discs:
      circle.backgroundColor = newColor(0.0, 0.0, 0.0, 1.0)
    else:
      circle.backgroundColor = newColor(0.0, 0.0, 0.0, 0.0)
    result.addSubview(circle)

  var count = 0
  setInterval 0.1, proc() =
    if board.current_turn == Black:
      if count < 10:
        echo count
        count += 1
        return
      echo count
      count = 0
      
      let list = board.possiblePutList
      if list.len > 0:
        board = board.put(board.possiblePutList.sample).turn()
      else:
        board = board.turn()

      collectionView.updateLayout()

  collectionView.itemSize = newSize(50, 50)
  collectionView.backgroundColor = newColor(0.0, 0.0, 0.0, 1.0)
  collectionView.updateLayout()
  wnd.addSubview(collectionView)

when isMainModule:
  runApplication:
    startApp()
