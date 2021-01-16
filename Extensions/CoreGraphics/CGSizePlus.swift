//
//  CoreGraphicPlus.swift
//  ExtensionDemo
//
//  Created by Choi on 2020/9/16.
//  Copyright © 2020 Choi. All rights reserved.
//

import UIKit

protocol SizeExtendable {
	
	/// 垂直方向扩展
	var vertical: CGFloat { get }
	
	/// 水平方向扩展
	var horizontal: CGFloat { get }
}

extension CGSize: SizeExtendable {
	var vertical: CGFloat { height }
	var horizontal: CGFloat { width }
}

extension CGSize {
    
	init(_ edges: CGFloat...) {
		guard let width = edges.first else { self.init(width: 0, height: 0); return }
		guard let height = edges.last else { self.init(width: 0, height: 0); return }
		self.init(width: width, height: height)
	}
	/// 给CGSize加另外的宽高
	/// - Parameters:
	///   - lhs: CGSize
	///   - rhs: 遵循了ExtendableBySize协议的对象
	/// - Returns: A new CGSize
	static func + (lhs: CGSize, rhs: SizeExtendable) -> CGSize {
		var size = lhs
		size.width += rhs.horizontal
		size.height += rhs.vertical
		return size
	}
    
    var ratio: CGFloat {
        height / width
    }
    
    func multiplied(by: CGFloat) -> CGSize {
        var size = self
        size.width *= by
        size.height *= by
        return size
    }
}
