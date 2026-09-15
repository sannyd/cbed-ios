//
//  SectionDetailViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/06/2021.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class SectionDetailViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var sectionImageView: UIImageView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var labelSectionName: UILabel!
    @IBOutlet weak var buttonBack: UIButton!
    @IBOutlet weak var buttonStart: CustomBorderButton!
    @IBOutlet weak var labelDisclaimer: UILabel!
    @IBOutlet weak var buttonOutline: CustomBorderButton!
    
    // MARK: - Properties
    
    var viewModel: SectionDetailViewModel!
    var disposeBag = DisposeBag()
    
    private var collectionView: AnswerCollectionView<CommonCollectionViewSection<UsefulLink>, UsefulLinkCell>!
    private let timerPickerView = UIPickerView()
    private let timerOptions = Array(1...500)
    private var selectedCustomTimerMinutes = 90
    private var customTimerTextField: UITextField?
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFonts()
        setupCollectionView()
        setupCustomTimerControlIfNeeded()
        bindViewModel()
        if [5, 40].contains(viewModel.level.id) {
            // Use the storyboard's MBE disclaimer text (set in Home.storyboard)
            labelDisclaimer.isHidden = false
        } else if [29, 30, 31, 33, 34, 35].contains(viewModel.level.id) {
            // Override with NextGen disclaimer text
            labelDisclaimer.text = "The NextGen Bar Exam questions, integrated question sets, performance tasks, and answer explanations (“Content”) provided in this application are copyrighted by the National Conference of Bar Examiners (“NCBE”). You are permitted to view the Content for your personal and non-commercial study use only. You are not permitted to copy, modify, reproduce, post, disclose, scrape, or distribute any of the Content in whole or in part, nor submit the Content into any artificial intelligence system. Any unauthorized use of the Content is a violation of NCBE’s rights and could subject you and others who are involved to criminal and civil penalties."
            labelDisclaimer.isHidden = false
        } else {
            labelDisclaimer.isHidden = true
        }
        
        if viewModel.level.id == 9 || viewModel.level.id == 7 || viewModel.level.id == 8 || viewModel.level.id == 10 || viewModel.level.id == 11 || viewModel.level.id == 13 || viewModel.level.id == 14 || viewModel.level.id == 31 || viewModel.level.id == 33 || viewModel.level.id == 34 || viewModel.level.id == 35 { // M/PT or Essay or Free or MEE or MPT or FL Essay Drills
            buttonOutline.isHidden = false
        }
        
        if viewModel.level.id == 7 { // MEE
            buttonOutline.setTitle("Essay Outline", for: .normal)
        }
        
        if viewModel.level.id == 14 { // GA Essay Drills
            buttonOutline.setTitle("Essay Outline", for: .normal)
        }
        
        if viewModel.level.id == 13 { // FL Essay Drills
            buttonOutline.setTitle("Essay Outline", for: .normal)
        }
        
        if viewModel.level.id == 9 { // Essay
            buttonOutline.setTitle("Essay Outline", for: .normal)
        }
        
        if viewModel.level.id == 8 { // Free
            buttonOutline.setTitle("Essay Outline", for: .normal)
        }

        if viewModel.level.id == 31 { // IQS Drafting Sets
            buttonOutline.setTitle("Drafting Outline", for: .normal)
        }

        if viewModel.level.id == 33 { // IQS Counseling Sets
            buttonOutline.setTitle("Counseling Outline", for: .normal)
        }
        
        if viewModel.level.id == 10 { // M/PT
            buttonOutline.setTitle("M/PT Outline", for: .normal)
        }
        
        if viewModel.level.id == 11 { // MPT
            buttonOutline.setTitle("MPT Outline", for: .normal)
        }

        if viewModel.level.id == 34 { // SPT
            buttonOutline.setTitle("SPT Outline", for: .normal)
        }

        if viewModel.level.id == 35 { // LRPT
            buttonOutline.setTitle("LRPT Outline", for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFonts()
        collectionView?.reloadData()
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    func bindViewModel() {
        let startTrigger: Observable<Int?> = buttonStart
            .rxButtonTapped
            .map { [weak self] () -> Int? in
                guard let self = self, self.viewModel.level.id == 40 else {
                    return nil
                }
                
                return self.selectedCustomTimerMinutes
            }
        
        let input = SectionDetailViewModel.Input(firstLoadTrigger: rxViewWillAppear,
                                                 usefulLinkTapped: collectionView.rxModelSelected(),
                                                 buttonStartTrigger: startTrigger,
                                                 buttonOutlineTrigger: buttonOutline.rxButtonTapped)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .usefulLinks
            .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource)),
         output
            .sectionDetail
            .drive(onNext: { [weak self] payload in
               
                self?.labelSectionName.text = payload.1.name
                self?.sectionImageView.loadImage(with: payload.0, placeholder: #imageLiteral(resourceName: "img_drill"))
            }),
         output
            .isLoading
            .drive(LoadingIndicatorView.rx.isAnimating),
         output
            .error
            .drive(errorBinding),
         buttonBack
            .rxButtonTapped
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func setupCollectionView() {
        collectionView = AnswerCollectionView<CommonCollectionViewSection<UsefulLink>, UsefulLinkCell>(lineSpacing: 14)
        collectionView.isScrollEnabled = false
        collectionView.contentInset = .init(top: 20,
                                            left: 0,
                                            bottom: 30,
                                            right: 0)
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(containerView.snp.edges) }
    }
    
    private func setupFonts() {
        labelSectionName.applyAppFontScaling()
        labelDisclaimer.applyAppFontScaling()
        customTimerTextField?.applyAppFontScaling()
    }

    private func setupCustomTimerControlIfNeeded() {
        guard viewModel.level.id == 40,
              let buttonStackView = buttonStart.superview as? UIStackView else {
            return
        }
        
        timerPickerView.delegate = self
        timerPickerView.dataSource = self
        if let defaultRow = timerOptions.firstIndex(of: selectedCustomTimerMinutes) {
            timerPickerView.selectRow(defaultRow, inComponent: 0, animated: false)
        }
        
        let container = CustomBorderView()
        container.backgroundColor = Constants.SecondarySurfaceColor
        container.borderRadius = 10
        container.topLeft = true
        container.topRight = true
        container.bottomLeft = true
        container.bottomRight = true
        
        let titleLabel = UILabel()
        titleLabel.text = "Timer"
        titleLabel.font = UIFont.appFont(name: Constants.Font.LatoBold, size: 14)
        titleLabel.textColor = Constants.PrimaryTextColor
        titleLabel.applyAppFontScaling()
        
        let textField = UITextField()
        textField.text = timerText(minutes: selectedCustomTimerMinutes)
        textField.textAlignment = .right
        textField.font = UIFont.appFont(name: Constants.Font.LatoBold, size: 16)
        textField.textColor = Constants.PrimaryBlue
        textField.tintColor = .clear
        textField.inputView = timerPickerView
        textField.inputAccessoryView = makeTimerPickerToolbar()
        textField.applyAppFontScaling()
        customTimerTextField = textField
        
        container.addSubview(titleLabel)
        container.addSubview(textField)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        textField.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.bottom.equalToSuperview()
        }
        container.snp.makeConstraints { make in
            make.height.equalTo(54)
        }
        
        buttonStackView.insertArrangedSubview(container,
                                             at: buttonStackView.arrangedSubviews.firstIndex(of: buttonStart) ?? buttonStackView.arrangedSubviews.count)
    }
    
    private func makeTimerPickerToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneSelectingTimer))
        ]
        return toolbar
    }
    
    @objc private func doneSelectingTimer() {
        customTimerTextField?.resignFirstResponder()
    }
    
    private func timerText(minutes: Int) -> String {
        "\(minutes) \(minutes == 1 ? "minute" : "minutes")"
    }
}

extension SectionDetailViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        timerOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        timerText(minutes: timerOptions[row])
    }
    
    func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        selectedCustomTimerMinutes = timerOptions[row]
        customTimerTextField?.text = timerText(minutes: selectedCustomTimerMinutes)
    }
}
