import nimx/[
  window,
  text_field,
  collection_view,
  timer,
  button
]
import std/[sets, random, math]

type
  PlayerTurn {.pure.} = enum
    Black, White
  
  Board = object
    white_discs: HashSet[int]
    black_discs: HashSet[int]
    current_turn: PlayerTurn

  AgentKind = enum
    akRandom
    akSimpleEvaluation

  Agent = object
    kind: AgentKind

func init (_: typedesc[Board]): Board =
  result = Board()
  result.current_turn = White

func init (_: typedesc[Agent], kind: AgentKind): Agent =
  result = Agent()
  result.kind = kind

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
  row += dy; col += dx
  while row >= 0 and row < 8 and col >= 0 and col < 8:
    yield toDiscNumber(row, col)
    row += dy; col += dx

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
  result = board
  for (row, col) in searching_vectors:
    var
      passed_opponent = false
      addition_disc: HashSet[int]
    for searching_disc_number in searchBoard(disc_number, row, col):
      if searching_disc_number in result.opponentsDiscs:
        passed_opponent = true
        addition_disc.incl searching_disc_number
      elif passed_opponent and (searching_disc_number in result.myDiscs):
        result.myDiscs = result.myDiscs + addition_disc
        result.opponentsDiscs = result.opponentsDiscs - addition_disc
        break
      else: break
  result = result.singleDrop(disc_number)

func possibleDropList (board: Board): seq[int] =
  for disc_number in 0 ..< 64:
    if board.canDrop(disc_number):
      result.add disc_number

var
  board = Board.init()
  agent = Agent.init(akSimpleEvaluation)
  start_flag = false

const
  disc_weight = [
    3.0,  -0.5,  1.5,  1.5,  1.5,  1.5, -0.5,  3.0,
    -0.5,  -2.0, -0.4, -0.2, -0.2, -0.4, -2.0, -0.5,
    1.5,  -0.4,  0.2,  0.2,  0.2,  0.2, -0.4,  1.5,
    1.5,  -0.2,  0.2,  0.2,  0.2,  0.2, -0.2,  1.5,
    1.5,  -0.2,  0.2,  0.2,  0.2,  0.2, -0.2,  1.5,
    1.5,  -0.4,  0.2,  0.2,  0.2,  0.2, -0.4,  1.5,
    -0.5,  -2.0, -0.4, -0.2, -0.2, -0.4, -2.0, -0.5,
    3.0,  -0.5,  1.5,  1.5,  1.5,  1.5, -0.5,  3.0
  ]

func cpu_based_score (board: Board): float =
  for black_disc in board.black_discs:
    result += disc_weight[black_disc]
  for white_disc in board.white_discs:
    result -= disc_weight[white_disc]

proc simpleEvaluation (board: Board, target: PlayerTurn, depth, target_depth: int): tuple[disc_number: int, score: float] =
  if depth == target_depth:
    result.score = board.cpu_based_score()
    echo target, " ", result.score
  else:
    if target == White: result.score = Inf
    else: result.score = -Inf
    for disc_number in board.possibleDropList:
      let dropped_board = board.drop(disc_number).turn()

      let new_score = simpleEvaluation(dropped_board, target, depth+1, target_depth).score
      if (target == White and min(result.score, new_score) == new_score) or (target == Black and max(result.score, new_score) == new_score):
        result.score = new_score
        result.disc_number = disc_number

proc choose (agent: Agent, board: Board): (Board, float) =
  case agent.kind
  of akRandom:
    result = (board.drop(board.possibleDropList.sample).turn(), NaN)
  of akSimpleEvaluation:
    var evaluated = board.simpleEvaluation(board.current_turn, 0, 2)
    result = (board.drop(evaluated.disc_number).turn(), evaluated.score)

func pass (agent: Agent, board: Board): Board =
  result = board.turn()

proc startApp() =
  var wnd = newWindow(newRect(40, 40, 700, 459))

  var label = newLabel(newRect(15, 425, 0, 20))
  wnd.addSubview(label)

  let collectionView = newCollectionView(newRect(0, 0, 419, 419), newSize(50, 50), LayoutDirection.LeftToRight)
  collectionView.numberOfItems = proc(): int = 64
  collectionView.viewForItem = proc(i: int): View =
    var button = newButton(newRect(0, 0, 100, 100))
    button.onAction(proc () =
      if board.canDrop(i):
        board = board.drop(i).turn()
        collectionView.updateLayout()

        if (board.black_discs + board.white_discs).len == 64:
          echo "finish"
          return
    )

    if board.canDrop(i):
      button.backgroundColor = newColor(0.0, 0.0, 1.0, 1.0)
    else:
      button.backgroundColor = newColor(0.0, 1.0, 0.0, 1.0)
    result = button
    var circle = newView(newRect(15, 15, 20, 20))
    var score_text = newLabel(newRect(10, 15, 30, 20))
    if i in board.white_discs:
      circle.backgroundColor = newColor(1.0, 1.0, 1.0, 1.0)
    elif i in board.black_discs:
      circle.backgroundColor = newColor(0.0, 0.0, 0.0, 1.0)
    else:
      circle.backgroundColor = newColor(0.0, 0.0, 0.0, 0.0)
    
    if board.canDrop(i):
      let dropped_board = board.drop(i).turn()
      # if board.current_turn == White:
      #   score_text.text = $(dropped_board.simpleEvaluation(dropped_board.current_turn, 0, 2).score.round(2) * -1)
      # else:
      #   score_text.text = $dropped_board.simpleEvaluation(dropped_board.current_turn, 0, 2).score.round(2)
      score_text.textColor = newColor(1.0, 1.0, 1.0, 1.0)
    result.addSubview(circle)
    result.addSubview(score_text)

  collectionView.itemSize = newSize(50, 50)
  collectionView.backgroundColor = newColor(0.0, 0.0, 0.0, 1.0)
  collectionView.updateLayout()
  wnd.addSubview(collectionView)


  var start_button = newButton(newRect(450, 15, 60, 20))
  discard newLabel(start_button, newPoint(0, 0), newSize(60, 20), "start")
  start_button.onAction(proc () =
    board.white_discs = toHashSet([27, 36])
    board.black_discs = toHashSet([28, 35])
    start_flag = true
    collectionView.updateLayout()
  )
  wnd.addSubview(start_button)

  setInterval 1.0, proc () =
    if board.current_turn == Black and start_flag:
      # agentが打つ
      var score = -Inf
      let list = board.possibleDropList
      if list.len > 0:
        (board, score) = agent.choose(board)
        label.text = "評価値: " & $(-score)
        echo "----------------------------------------"
      else:
        board = agent.pass(board)

      collectionView.updateLayout()

      if (board.black_discs + board.white_discs).len == 64:
        echo "finish"
        return

      if board.black_discs.len == 0 or board.white_discs.len == 0:
        echo "finish"
        return
    
      while board.possibleDropList.len == 0:
        board = board.turn()
        (board, score) = agent.choose(board)
        label.text = "評価値: " & $(-score)

      collectionView.updateLayout()

when isMainModule:
  runApplication:
    startApp()
