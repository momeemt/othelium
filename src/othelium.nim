import nimx/[
  window,
  text_field,
  collection_view,
  timer,
  button
]
import std/[sets, random]

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

iterator searchBoard (disc_number, dy, dx: int): int =
  var (row, col) = disc_number.toCoord()
  while row >= 0 and row < 8 and col >= 0 and col < 8:
    row += dy; col += dx
    yield toDiscNumber(row, col)

func product [I: static int, T] (arr1, arr2: array[I, T]): HashSet[(T, T)] =
  for elem1 in arr1:
    for elem2 in arr2:
      result.incl (elem1, elem2)

const searching_vectors = product([0, 1, -1], [0, 1, -1]) - toHashSet([(0, 0)])

proc canDrop (board: Board, disc_number: int): bool =
  if disc_number in board.black_discs or disc_number in board.white_discs:
    return false
  for (row, col) in searching_vectors:
    var passed_opponent = false
    for searching_disc_number in searchBoard(disc_number, row, col):
      if searching_disc_number in board.opponentsDiscs:
        passed_opponent = true
      elif passed_opponent and searching_disc_number in board.myDiscs:
        return true
      else:
        break

func singleDrop (board: Board, disc_number: int): Board =
  result = board
  case result.current_turn
  of White: result.white_discs.incl disc_number
  of Black: result.black_discs.incl disc_number

func drop (board: Board, disc_number: int): Board =
  result = board.singleDrop(disc_number)
  for (row, col) in searching_vectors:
    var
      passed_opponent = false
      addition_disc: HashSet[int]
    for searching_disc_number in searchBoard(disc_number, row, col):
      if searching_disc_number in result.opponentsDiscs:
        passed_opponent = true
        addition_disc.incl searching_disc_number
      elif passed_opponent and searching_disc_number in result.myDiscs:
        result.myDiscs = result.myDiscs + addition_disc
        result.opponentsDiscs = result.opponentsDiscs - addition_disc
      else: break

func possiblePutList (board: Board): seq[int] =
  for disc_number in 0 ..< 64:
    if board.canDrop(disc_number):
      result.add disc_number

var board = Board.init()

proc startApp() =
  var wnd = newWindow(newRect(40, 40, 419, 419))

  let collectionView = newCollectionView(newRect(0, 0, 419, 419), newSize(50, 50), LayoutDirection.LeftToRight)
  collectionView.numberOfItems = proc(): int =
    return 64
  collectionView.viewForItem = proc(i: int): View =
    var button = newButton(newRect(0, 0, 100, 100))
    button.onAction(proc () =
      if board.canDrop(i):
        board = board.drop(i).turn()
        collectionView.updateLayout()
    )

    if board.canDrop(i):
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

  setInterval 0.75, proc() =
    if board.current_turn == Black:
      let list = board.possiblePutList
      if list.len > 0:
        board = board.drop(board.possiblePutList.sample).turn()
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
