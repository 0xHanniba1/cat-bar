import Cocoa

class PixelCatView: NSView {
    var currentFrame = 0
    var facingRight = true
    var pixelSize: CGFloat = 2

    // 橘猫颜色
    private let orangeColor = NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
    private let darkOrangeColor = NSColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)
    private let whiteColor = NSColor.white
    private let blackColor = NSColor.black
    private let pinkColor = NSColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)

    // 像素猫跑动帧 (0=透明, 1=橘色, 2=深橘色, 3=白色, 4=黑色, 5=粉色)
    // 每帧是一个二维数组，从上到下，从左到右
    private let runFrames: [[[Int]]] = [
        // 帧1 - 腿伸展
        [
            [0,0,0,1,1,0,0,0,0,0,0,0],
            [0,0,1,1,1,1,0,0,0,0,0,0],
            [0,0,1,4,1,4,0,0,0,0,0,0],
            [0,0,0,1,1,1,0,0,0,0,0,0],
            [0,1,1,1,1,1,1,1,1,0,0,0],
            [1,1,1,1,1,1,1,1,1,1,0,0],
            [1,1,1,1,1,1,1,1,1,1,1,0],
            [0,1,1,1,1,1,1,1,1,1,1,1],
            [0,0,1,1,1,1,1,1,1,1,1,0],
            [0,0,1,0,0,1,1,0,0,1,0,0],
            [0,1,1,0,0,0,0,0,0,1,1,0],
        ],
        // 帧2 - 腿收起
        [
            [0,0,0,1,1,0,0,0,0,0,0,0],
            [0,0,1,1,1,1,0,0,0,0,0,0],
            [0,0,1,4,1,4,0,0,0,0,0,0],
            [0,0,0,1,1,1,0,0,0,0,0,0],
            [0,1,1,1,1,1,1,1,1,0,0,0],
            [1,1,1,1,1,1,1,1,1,1,0,0],
            [1,1,1,1,1,1,1,1,1,1,1,0],
            [0,1,1,1,1,1,1,1,1,1,1,1],
            [0,0,1,1,1,1,1,1,1,1,1,0],
            [0,0,0,1,1,0,0,1,1,0,0,0],
            [0,0,0,1,0,0,0,0,1,0,0,0],
        ],
        // 帧3 - 腿交叉1
        [
            [0,0,0,1,1,0,0,0,0,0,0,0],
            [0,0,1,1,1,1,0,0,0,0,0,0],
            [0,0,1,4,1,4,0,0,0,0,0,0],
            [0,0,0,1,1,1,0,0,0,0,0,0],
            [0,1,1,1,1,1,1,1,1,0,0,0],
            [1,1,1,1,1,1,1,1,1,1,0,0],
            [1,1,1,1,1,1,1,1,1,1,1,0],
            [0,1,1,1,1,1,1,1,1,1,1,1],
            [0,0,1,1,1,1,1,1,1,1,1,0],
            [0,0,0,0,1,1,1,1,0,0,0,0],
            [0,0,0,1,0,0,0,0,1,0,0,0],
        ],
        // 帧4 - 腿交叉2
        [
            [0,0,0,1,1,0,0,0,0,0,0,0],
            [0,0,1,1,1,1,0,0,0,0,0,0],
            [0,0,1,4,1,4,0,0,0,0,0,0],
            [0,0,0,1,1,1,0,0,0,0,0,0],
            [0,1,1,1,1,1,1,1,1,0,0,0],
            [1,1,1,1,1,1,1,1,1,1,0,0],
            [1,1,1,1,1,1,1,1,1,1,1,0],
            [0,1,1,1,1,1,1,1,1,1,1,1],
            [0,0,1,1,1,1,1,1,1,1,1,0],
            [0,0,0,1,0,0,0,0,1,0,0,0],
            [0,0,1,1,0,0,0,0,1,1,0,0],
        ],
    ]

    override var isFlipped: Bool { return true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard currentFrame < runFrames.count else { return }

        let frameData = runFrames[currentFrame]

        for (rowIndex, row) in frameData.enumerated() {
            for (colIndex, pixel) in row.enumerated() {
                if pixel == 0 { continue } // 透明

                let color: NSColor
                switch pixel {
                case 1: color = orangeColor
                case 2: color = darkOrangeColor
                case 3: color = whiteColor
                case 4: color = blackColor
                case 5: color = pinkColor
                default: continue
                }

                color.setFill()

                let x: CGFloat
                if facingRight {
                    x = CGFloat(colIndex) * pixelSize
                } else {
                    // 水平翻转
                    x = CGFloat(row.count - 1 - colIndex) * pixelSize
                }
                let y = CGFloat(rowIndex) * pixelSize

                let rect = NSRect(x: x, y: y, width: pixelSize, height: pixelSize)
                rect.fill()
            }
        }
    }

    func nextFrame() {
        currentFrame = (currentFrame + 1) % runFrames.count
        needsDisplay = true
    }

    func setDirection(right: Bool) {
        if facingRight != right {
            facingRight = right
            needsDisplay = true
        }
    }
}
