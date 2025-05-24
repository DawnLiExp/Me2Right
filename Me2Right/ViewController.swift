//
//  ViewController.swift
//  Me2Right
//
//  Created by me2 on 2025/5/20.
//

import Cocoa

class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let button = NSButton(title: "测试扩展", target: self, action: #selector(testExtension))
        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 30
        button.frame = NSRect(
            x: (view.bounds.width - buttonWidth) / 2,
            y: (view.bounds.height - buttonHeight) / 2,
            width: buttonWidth,
            height: buttonHeight
        )
        view.addSubview(button)
    }

    @objc func testExtension() {
        NSLog("测试扩展按钮被点击")
    }
}
