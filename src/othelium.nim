import nimx/[
  window,
  text_field,
  collection_view,
  timer,
  button
]
import std/[sets, random, math]
import otheliumpkg/[board]

type
  AgentKind = enum
    akRandom
    akSimpleEvaluation

  Agent = object
    kind: AgentKind

func init (_: typedesc[Agent], kind: AgentKind): Agent =
  result = Agent()
  result.kind = kind

var
  othello_board = initBoard()
  agent = Agent.init(akSimpleEvaluation)
  start_flag = false

const
  disc_weight = [
    30, -12, 0, -1, -1, 0, -12, 30,
    -12, -15, -3, -3, -3, -3, -15, -12,
    0, -3, 0, -1, -1, 0, -3, 0,
    -1, -3, -1, -1, -1, -1, -3, -1,
    -1, -3, -1, -1, -1, -1, -3, -1,
    0, -3, 0, -1, -1, 0, -3, 0,
    -12, -15, -3, -3, -3, -3, -15, -12,
    30, -12, 0, -1, -1, 0, -12, 30,
  ]

func score (board: Board): int =
  for my_disc in board.myDiscs:
    result += disc_weight[^my_disc]
  for opponent_disc in board.opponentsDiscs:
    result -= disc_weight[^opponent_disc]

proc simpleEvaluation (board: Board, depth, target_depth: int): tuple[disc: Disc, score: int] =
  if depth == target_depth:
    result.score = board.score()
  else:
    result.score = int.high
    for disc in board.discsPossibleToDrop:
      let dropped_board = board.drop(disc).changeTurn()

      let new_score = simpleEvaluation(dropped_board, depth+1, target_depth).score
      if min(result.score, new_score) == new_score:
        result.score = new_score
        result.disc = disc

proc choose (agent: Agent, board: Board): (Board, int) =
  case agent.kind
  of akRandom:
    result = (board.drop(@(board.discsPossibleToDrop).sample).changeTurn(), 0)
  of akSimpleEvaluation:
    var evaluated = board.simpleEvaluation(0, 2)
    result = (board.drop(evaluated.disc).changeTurn(), evaluated.score)

func pass (agent: Agent, board: Board): Board =
  result = board.changeTurn()

proc startApp() =
  var wnd = newWindow(newRect(40, 40, 700, 459))

  var label = newLabel(newRect(15, 425, 0, 20))
  wnd.addSubview(label)

  let collectionView = newCollectionView(newRect(0, 0, 419, 419), newSize(50, 50), LayoutDirection.LeftToRight)
  collectionView.numberOfItems = proc(): int = 64
  collectionView.viewForItem = proc(i: int): View =
    var button = newButton(newRect(0, 0, 100, 100))
    let disc = initDisc(i)

    button.onAction(proc () =
      if othello_board.canDrop(disc):
        othello_board = othello_board.drop(disc).changeTurn()
        collectionView.updateLayout()

        if othello_board.finished:
          echo "finish"
          return
    )
    result = button

    if othello_board.canDrop(disc):
      button.backgroundColor = newColor(0.0, 0.0, 1.0, 1.0)
    else:
      button.backgroundColor = newColor(0.0, 1.0, 0.0, 1.0)
    
    var circle = newView(newRect(15, 15, 20, 20))
    var score_text = newLabel(newRect(10, 15, 30, 20))
    if disc in othello_board.white_discs:
      circle.backgroundColor = newColor(1.0, 1.0, 1.0, 1.0)
    elif disc in othello_board.black_discs:
      circle.backgroundColor = newColor(0.0, 0.0, 0.0, 1.0)
    else:
      circle.backgroundColor = newColor(0.0, 0.0, 0.0, 0.0)
    
    if othello_board.canDrop(disc):
      let dropped_board = othello_board.drop(disc).changeTurn()
      if othello_board.current_turn == White:
        score_text.text = $(dropped_board.simpleEvaluation(0, 2).score)
      else:
        score_text.text = $(-dropped_board.simpleEvaluation(0, 2).score)
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
    othello_board.myDiscs =  initDiscs(initDisc(3, 3), initDisc(4, 4))
    othello_board.opponentsDiscs = initDiscs(initDisc(4, 3), initDisc(3, 4))
    start_flag = true
    collectionView.updateLayout()
  )
  wnd.addSubview(start_button)

  setInterval 1.0, proc () =
    if othello_board.current_turn == Black and start_flag:
      # agentが打つ
      var score = int.low
      let list = othello_board.discsPossibleToDrop
      if list.len > 0:
        (othello_board, score) = agent.choose(othello_board)
        label.text = "評価値: " & $(-score)
        echo "----------------------------------------"
      else:
        othello_board = agent.pass(othello_board)

      collectionView.updateLayout()

      if othello_board.finished:
        echo "finish"
        return
    
      while othello_board.discsPossibleToDrop.len == 0:
        othello_board = othello_board.changeTurn()
        (othello_board, score) = agent.choose(othello_board)
        label.text = "評価値: " & $(-score)

      collectionView.updateLayout()

when isMainModule:
  runApplication:
    startApp()
