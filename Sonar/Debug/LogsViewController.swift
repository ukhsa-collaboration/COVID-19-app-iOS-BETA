//
//  LogsViewController.swift
//  Sonar
//
//  Created by NHSX on 01/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import UIKit

#if DEBUG || INTERNAL

class LogsViewController: UIViewController {
    
    private var observations = [NSKeyValueObservation]()
    
    @IBOutlet weak private var textView: UITextView!
        
    private var autoScrollEnabled = true {
        didSet {
            updateAutoscrollButtons()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateAutoscrollButtons()
        
        textView.observe(\.contentSize) { [weak self] (textView, _) in
            self?.contentSizeDidChange(on: textView)
        }.append(to: &observations)
        
        LoggingManager.shared.observe(\.log, options: [.initial, .new]) { [weak self] (_, log) in
            self?.textView.text = log.newValue ?? ""
        }.append(to: &observations)
    }
    
    @objc private func toggleAutoscroll() {
        autoScrollEnabled.toggle()
    }
    
    private func updateAutoscrollButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: autoScrollEnabled ? "Auto scroll enabled" : "Auto scroll disabled",
            style: .plain,
            target: self,
            action: #selector(toggleAutoscroll)
        )
    }
    
    private func contentSizeDidChange(on textView: UITextView) {
        guard autoScrollEnabled else { return }
        var contentOffset = textView.contentOffset
        contentOffset.y = max(-textView.adjustedContentInset.top, textView.contentSize.height - textView.frame.height + textView.adjustedContentInset.bottom)
        DispatchQueue.main.async {
            textView.setContentOffset(contentOffset, animated: false)
        }
    }
    
}

private extension NSKeyValueObservation {
    
    func append(to array: inout [NSKeyValueObservation]) {
        array.append(self)
    }
    
}

#endif
