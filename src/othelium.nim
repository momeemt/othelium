import nimx/[
  window,
  text_field,
  collection_view,
  button
]

var
  current_white_board = @[27, 36]
  current_black_board = @[28, 35]

proc startApp() =
  var wnd = newWindow(newRect(40, 40, 419, 419))

  let collectionView = newCollectionView(newRect(0, 0, 419, 419), newSize(50, 50), LayoutDirection.LeftToRight)
  collectionView.numberOfItems = proc(): int =
    return 64
  collectionView.viewForItem = proc(i: int): View =
    var button = newButton(newRect(0, 0, 100, 100))
    button.onAction(proc () =
      echo i
    )
    button.backgroundColor = newColor(0.0, 1.0, 0.0, 1.0)
    result = button
    
    var circle = newView(newRect(15, 15, 20, 20))
    if i in current_white_board:
      circle.backgroundColor = newColor(1.0, 1.0, 1.0, 1.0)
    elif i in current_black_board:
      circle.backgroundColor = newColor(0.0, 0.0, 0.0, 1.0)
    else:
      circle.backgroundColor = newColor(0.0, 0.0, 0.0, 0.0)
    result.addSubview(circle)
  collectionView.itemSize = newSize(50, 50)
  collectionView.backgroundColor = newColor(0.0, 0.0, 0.0, 1.0)
  collectionView.updateLayout()
  wnd.addSubview(collectionView)

when isMainModule:
  runApplication:
    startApp()
