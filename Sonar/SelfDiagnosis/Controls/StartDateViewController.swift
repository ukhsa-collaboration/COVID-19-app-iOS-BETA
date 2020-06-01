//
//  StartDateViewController.swift
//  Sonar
//
//  Created by NHSX on 4/17/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

import Logging

protocol StartDateViewControllerDelegate: class {
    func startDateViewController(_ vc: StartDateViewController, didSelectDate date: Date)
}

class StartDateViewController: UIViewController {

    private var symptoms: Symptoms!
    weak var delegate: StartDateViewControllerDelegate?

    func inject(symptoms: Symptoms, delegate: StartDateViewControllerDelegate) {
        self.symptoms = symptoms
        self.delegate = delegate
    }

    private var startDate: Date? {
        didSet {
            guard let date = startDate else {
                return
            }

            button.text = dateFormatter.string(from: date)
            delegate?.startDateViewController(self, didSelectDate: date)
        }
    }

    private let logger = Logger(label: String(describing: self))

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var errorView: ErrorView!
    @IBOutlet weak var button: StartDateButton!

    @IBOutlet var datePicker: UIPickerView!

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    var dateOptions: [Date] = {
        let today = Date()
        return (-27...0).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: today) }.reversed()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.translatesAutoresizingMaskIntoConstraints = false

        label.text = "SYMPTOMS_START_QUESTION".localized
        errorView.isHidden = true
        errorView.errorMessage.text = "SYMPTOMS_START_ERROR".localized

        button.text = "SELECT_START_DATE".localized
    }

    @IBAction func buttonTapped(_ sender: StartDateButton) {
        startDate = dateOptions[datePicker.selectedRow(inComponent: 0)]
        showPicker()
    }

    // MARK: - Support for Dyanmic Type
    
    private func showPicker() {
        scroll(to: self.datePicker) {
            self.datePicker.isHidden = !self.datePicker.isHidden
        }
    }

    private func makeLabelForPickerRow() -> UILabel {
        let label = UILabel()
        label.font = datePickerRowFont
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }
        
    private lazy var datePickerRowHeight: CGFloat = {
        return dateOptions.map(heightForRowWithDate).max()!
    }()
    
    private lazy var datePickerRowFont: UIFont? = {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        guard let size = descriptor.object(forKey: .size) as? NSNumber else {
            logger.error("Could not get size of body font")
            return nil
        }

        return UIFont.systemFont(ofSize: CGFloat(size.doubleValue))

    }()
    
    private func heightForRowWithDate(_ date: Date) -> CGFloat {
        let max = CGSize(width: datePicker.bounds.size.width, height: .greatestFiniteMagnitude)
        let label = makeLabelForPickerRow()
        label.frame = CGRect(origin: .zero, size: max)
        label.text = titleForPickerRowWithDate(date)
        label.sizeToFit()
        let spacing = CGFloat(16)
        return label.frame.height + spacing
    }

}

extension StartDateViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dateOptions.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = view as? UILabel ?? makeLabelForPickerRow()
        label.text = self.pickerView(pickerView, titleForRow: row, forComponent: component)
        label.numberOfLines = 0
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return datePickerRowHeight
    }
}

extension StartDateViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return titleForPickerRowWithDate(dateOptions[row])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        startDate = dateOptions[row]
    }
    
    private func titleForPickerRowWithDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
}

class StartDateButton: UnderlinedButton {
    override var canBecomeFirstResponder: Bool {
        true
    }

    private var _inputView: UIView?
    override var inputView: UIView? {
        get { _inputView }
        set { _inputView = newValue }
    }

    private var _inputAccessoryView: UIView?
    override var inputAccessoryView: UIView? {
        get { _inputAccessoryView }
        set { _inputAccessoryView = newValue }
    }

    var text: String? {
        get { title(for: .normal) }
        set { setTitle(newValue, for: .normal) }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.cornerRadius = 8
    }
}
