//: 2048 Playground - by Kyle Spadaro

import UIKit
import PlaygroundSupport
import GameplayKit

/// Movement orientation
enum Orientation {
    case vertical
    case horizon
}

/// Movement direction
enum Direction : Int {
    case forward = 1
    case backward = -1
}

/// Position of tiles in the board
struct Position : Equatable{
    let x : Int
    let y : Int
    
    /// find previous position according to the direction and orientation
    func previousPosition(direction:Direction, orientation:Orientation) -> Position {
        switch orientation {
        case .vertical:
            return Position(x: x, y: y - direction.rawValue)
        case .horizon:
            return Position(x: x - direction.rawValue, y: y)
        }
    }
}

func ==(lhs: Position, rhs: Position) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

/// Style configuration of the game
struct Style {
    let boardBackgroundColor        = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    let emptyTileBackgroundColor    = #colorLiteral(red: 0.803921580314636, green: 0.803921580314636, blue: 0.803921580314636, alpha: 1.0)
    let tileBackgroundColors = [
        #colorLiteral(red: 0.254901975393295, green: 0.274509817361832, blue: 0.301960796117783, alpha: 1.0), #colorLiteral(red: 0.600000023841858, green: 0.600000023841858, blue: 0.600000023841858, alpha: 1.0), #colorLiteral(red: 0.501960813999176, green: 0.501960813999176, blue: 0.501960813999176, alpha: 1.0), #colorLiteral(red: 0.254901975393295, green: 0.274509817361832, blue: 0.301960796117783, alpha: 1.0),
        #colorLiteral(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0), #colorLiteral(red: 0.925490200519562, green: 0.235294118523598, blue: 0.10196078568697, alpha: 1.0), #colorLiteral(red: 0.937254905700684, green: 0.34901961684227, blue: 0.192156866192818, alpha: 1.0), #colorLiteral(red: 0.745098054409027, green: 0.156862750649452, blue: 0.0745098069310188, alpha: 1.0),
        #colorLiteral(red: 0.341176480054855, green: 0.623529434204102, blue: 0.168627455830574, alpha: 1.0), #colorLiteral(red: 0.258823543787003, green: 0.756862759590149, blue: 0.968627452850342, alpha: 1.0), #colorLiteral(red: 0.968627452850342, green: 0.780392169952393, blue: 0.345098048448563, alpha: 1.0), #colorLiteral(red: 0.9098039216, green: 0.737254902, blue: 0.03921568627, alpha: 1)
    ]
    let tileForgroundColors = [
        #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
        UIColor.white
    ]
    
    /// tile background color according to the value of the tile
    func tileBackgroundColor(value:Int) -> CGColor {
        return value < tileBackgroundColors.count ? tileBackgroundColors[value].cgColor : tileBackgroundColors.last!.cgColor
    }
    
    /// tile text color according to the value of the tile
    func tileForgroundColor(value:Int) -> UIColor {
        return tileForgroundColors[value > 2 ? 1 : 0]
    }
}

/// size configuration of the board
struct BoardSizeConfig {
    let tileNumber = 4
    let tileCount  = 16
    let boardSize   = CGSize(width: 290, height: 290)
    let tileSize    = CGSize(width: 60, height: 60)
    let borderSize  = CGSize(width: 10, height: 10)
}
let style = Style()
let config = BoardSizeConfig()

class Tile : Equatable {
    var value : Int = 0 {
        didSet {
            updateView()
        }
    }
    var valueText : String {
        return value == 0 ? "" : "\(1<<value)"
    }
    var valueLength : Int {
        return valueText.characters.count
    }
    
    var isEmpty : Bool {
        return value == 0
    }
    
    let view : UILabel = UILabel(frame: .zero)
    var position : Position {
        didSet {
            guard let board = self.board else {
                return
            }
            let point = board.pointAt(position: self.position)
            self.topConstraint?.constant = point.y
            self.leftConstraint?.constant = point.x
        }
    }
    
    var board : Board?
    var topConstraint : NSLayoutConstraint?
    var leftConstraint : NSLayoutConstraint?
    
    init(value: Int, position : Position = Position(x: 0, y: 0) ){
        self.position = position
        view.textAlignment = .center
        view.layer.cornerRadius = 3
        view.translatesAutoresizingMaskIntoConstraints = false
        self.value = value
        updateView()
    }
    
    func fontSize(for length: Int) -> CGFloat {
        if length > 4 {
            return 18
        } else if length > 3 {
            return 20
        }
        return 30
    }
    func updateView() {
        view.text = valueText
        view.font = UIFont.boldSystemFont(ofSize: fontSize(for: valueLength))
        view.layer.backgroundColor = style.tileBackgroundColor(value: value)
        view.textColor = style.tileForgroundColor(value: value)
    }
    
    func moveTo(position:Position) {
        self.position = position
    }
    
    func mergeTo(position:Position) {
        moveTo(position: position)
        self.value += 1
    }
    
    func addTo(board:Board) {
        guard self.board == nil else {
            return
        }
        self.board = board
        let boardView = board.boardView
        boardView.addSubview(view)
        view.widthAnchor.constraint(equalToConstant: config.tileSize.width).isActive = true
        view.heightAnchor.constraint(equalToConstant: config.tileSize.height).isActive = true
        
        let point = board.pointAt(position:self.position)
        topConstraint = view.topAnchor.constraint(equalTo: boardView.topAnchor, constant: point.y)
        leftConstraint = view.leftAnchor.constraint(equalTo: boardView.leftAnchor, constant: point.x)
        topConstraint?.isActive = true
        leftConstraint?.isActive = true
    }
    
    func removeFromBoard() {
        self.view.removeFromSuperview()
    }
    
    func createPreviousEmptyTile(direction:Direction, orientation:Orientation) -> Tile {
        let pos = self.position.previousPosition(direction: direction, orientation: orientation)
        return Tile(value: 0, position: pos)
    }
}

func ==(lhs: Tile, rhs: Tile) -> Bool {
    return lhs.value == rhs.value && lhs.position == rhs.position
}

class Board {
    let boardView : UIView
    var tileArray = [Tile]()
    
    init() {
        boardView = UIView(frame: .zero)
        boardView.backgroundColor = style.boardBackgroundColor
        boardView.layer.cornerRadius = 6
        boardView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func pointAt(x:Int, y:Int) -> CGPoint {
        let offsetX = config.borderSize.width
        let offsetY = config.borderSize.height
        let width = config.tileSize.width + config.borderSize.width
        let height = config.tileSize.height + config.borderSize.height
        return CGPoint(x: offsetX + width * CGFloat(x), y: offsetY + height * CGFloat(y))
    }
    
    func pointAt(position:Position) -> CGPoint {
        return pointAt(x: position.x, y: position.y)
    }
    
    func addTo(view : UIView){
        view.addSubview(self.boardView)
        boardView.widthAnchor.constraint(equalToConstant: config.boardSize.width).isActive = true
        boardView.heightAnchor.constraint(equalTo: boardView.widthAnchor).isActive = true
        boardView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        boardView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    func gameOver() {
        print("game over")
    }
    
    func add(tile:Tile) {
        tile.addTo(board: self)
        tileArray.append(tile)
    }
    
    func generateTile() {
        guard tileArray.count <= config.tileCount else {
            print("no space available")
            return
                print("Game Over")
            return
        }
        
        var tileList : [(Int,Int)?] = Array(repeating: nil, count: config.tileCount)
        for x in 0..<config.tileNumber {
            for y in 0..<config.tileNumber {
                tileList[x+y*config.tileNumber] = (x,y)
            }
        }
        for tile in tileArray {
            tileList[tile.position.x + tile.position.y * config.tileNumber] = nil
        }
        let remain = tileList.flatMap {$0}
        let random = arc4random_uniform(UInt32(remain.count))
        let value = Int(arc4random_uniform(3)/2)+1
        let (x, y) = remain[Int(random)]
        let tile = Tile(value: value, position: Position(x: x, y: y))
        
        tile.addTo(board: self)
        tileArray.append(tile)
    }
    
    func buildBoard() {
        for i in 0..<4 {
            for j in 0..<4 {
                let layer = CALayer()
                layer.frame = CGRect(origin: pointAt(x: i, y: j), size: config.tileSize)
                layer.backgroundColor = style.emptyTileBackgroundColor.cgColor
                layer.cornerRadius = 3
                boardView.layer.addSublayer(layer)
            }
        }
        generateTile()
        generateTile()
    }
    
    func removeFromTileArray(tile:Tile) {
        if let idx = tileArray.index(where: {$0 == tile}) {
            tileArray.remove(at: idx)
            tile.removeFromBoard()
        }
    }
    func checkMovement(direction:Direction, orientation:Orientation) -> Bool {
        var moved = false
        var tileList = [Tile]()
        for y in 0..<config.tileNumber {
            for x in 0..<config.tileNumber {
                let tile = Tile(value: 0, position: Position(x: x, y: y))
                tileList.append(tile)
            }
        }
        for tile in tileArray {
            tileList[tile.position.x + tile.position.y * config.tileNumber] = tile
        }
        var lastZeroTile : Tile? = nil
        var lastMergableTile : Tile? = nil
        for i in 0..<config.tileNumber {
            lastZeroTile = nil
            lastMergableTile = nil
            for j in 0..<config.tileNumber {
                let temp = direction == .forward ? (config.tileNumber - 1) - j : j
                let x = orientation == .horizon ? temp : i
                let y = orientation == .horizon ? i : temp
                let tile = tileList[x + y * config.tileNumber]
                if !tile.isEmpty {
                    if let mergableTile = lastMergableTile, mergableTile.value == tile.value {
                        tile.mergeTo(position: mergableTile.position)
                        removeFromTileArray(tile: mergableTile)
                        lastMergableTile = nil
                        lastZeroTile = tile.createPreviousEmptyTile(direction: direction, orientation: orientation)
                        moved = true
                        continue
                    }
                    if let zeroTile = lastZeroTile {
                        tile.moveTo(position: zeroTile.position)
                        lastZeroTile = tile.createPreviousEmptyTile(direction: direction, orientation: orientation)
                        moved = true
                    }
                    lastMergableTile = tile
                } else {
                    if lastZeroTile == nil {
                        lastZeroTile = tile
                    }
                }
            }
        }
        return moved
    }
    
    func moveTile(direction: Direction, orientation: Orientation) {
        let moved = checkMovement(direction: direction, orientation: orientation)
        UIView.animate(withDuration: 0.1, animations: {
            self.boardView.layoutIfNeeded()
        }) { (_) in
            if moved {
                self.generateTile()
            }
        }
    }
}

class GameViewController : UIViewController {
    let board = Board()
    
    @IBAction func swipe(recognizer:UIGestureRecognizer?) {
        guard let recognizer = recognizer as? UISwipeGestureRecognizer else {
            return
        }
        switch recognizer.direction {
        case UISwipeGestureRecognizerDirection.right:
            board.moveTile(direction: .forward, orientation: .horizon)
        case UISwipeGestureRecognizerDirection.left:
            board.moveTile(direction: .backward, orientation: .horizon)
        case UISwipeGestureRecognizerDirection.up:
            board.moveTile(direction: .backward, orientation: .vertical)
        case UISwipeGestureRecognizerDirection.down:
            board.moveTile(direction: .forward, orientation: .vertical)
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        if let view = self.view {
            view.backgroundColor = UIColor(white: 1.0, alpha: 1)
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            for direction : UISwipeGestureRecognizerDirection in [.left, .right, .up, .down] {
                let gesture = UISwipeGestureRecognizer(target: self, action: #selector(swipe))
                gesture.direction = direction
                view.addGestureRecognizer(gesture)
            }
            
            board.addTo(view: view)
            board.buildBoard()
        }
    }
}

let controller = GameViewController()
PlaygroundPage.current.liveView = controller
