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
  result.white_discs = toHashSet([27, 36])
  result.black_discs = toHashSet([28, 35])
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
  lambda_value = 4.0

func score (board: Board): float =
  ## CPU基準の評価値
  for black_disc in board.black_discs:
    result += disc_weight[black_disc]
  for white_disc in board.white_discs:
    result -= disc_weight[white_disc]

proc choose (agent: Agent, board: Board): (Board, float) =
  case agent.kind
  of akRandom:
    result = (board.drop(board.possibleDropList.sample).turn(), NaN)
  of akSimpleEvaluation:
    var evaluated: tuple[board: Board, score: float] = (Board.init(), -Inf)
    for disc_number in board.possibleDropList:
      let after_1turn_board = board.drop(disc_number).turn() # CPUの着手
      let player_count = after_1turn_board.possibleDropList.len # プレイヤーの着手可能数

      let after_1turn_score = after_1turn_board.score()
      
      var
        minimum_after_2turn_score = Inf
        cpu_count = 0
      for after_1turn_disc_number in after_1turn_board.possibleDropList:
        let after_2turn_board = after_1turn_board.drop(after_1turn_disc_number).turn() # プレイヤーの着手        
        let after_2turn_score = after_2turn_board.score()
        
        if minimum_after_2turn_score > after_2turn_score:
          minimum_after_2turn_score = after_2turn_score
          cpu_count = after_2turn_board.possibleDropList.len
        
      let score = (cpu_count - player_count).float + (minimum_after_2turn_score - after_1turn_score) * lambda_value
      if score > evaluated.score:
        evaluated.score = score
        evaluated.board = after_1turn_board
    result = evaluated

func pass (agent: Agent, board: Board): Board =
  result = board.turn()

proc startApp() =
  var wnd = newWindow(newRect(40, 40, 419, 459))

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
      if board.current_turn == White:
        score_text.text = $(dropped_board.score().round(2) * -1)
      else:
        score_text.text = $dropped_board.score().round(2)
      score_text.textColor = newColor(1.0, 1.0, 1.0, 1.0)
    result.addSubview(circle)
    result.addSubview(score_text)

  collectionView.itemSize = newSize(50, 50)
  collectionView.backgroundColor = newColor(0.0, 0.0, 0.0, 1.0)
  collectionView.updateLayout()
  wnd.addSubview(collectionView)

  setInterval 1.0, proc () =
    if board.current_turn == Black:
      # agentが打つ
      var score = -Inf
      let list = board.possibleDropList
      if list.len > 0:
        (board, score) = agent.choose(board)
        label.text = "評価値: " & $(-score)
      else:
        board = agent.pass(board)

      collectionView.updateLayout()

      if (board.black_discs + board.white_discs).len == 64:
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
