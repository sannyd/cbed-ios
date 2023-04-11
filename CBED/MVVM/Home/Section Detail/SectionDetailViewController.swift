//
//  SectionDetailViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

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
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        bindViewModel()
        if viewModel.level.id != 5 {
            labelDisclaimer.isHidden = true
        }
        
        if viewModel.level.id == 9 || viewModel.level.id == 8 || viewModel.level.id == 10 { // PT or Essay or Free
            buttonOutline.isHidden = false
        }
        
        if viewModel.level.id == 9 { // Essay
            buttonOutline.setTitle("Essay Outline", for: .normal)
        }
        
        if viewModel.level.id == 8 { // Free
            buttonOutline.setTitle("Essay Outline", for: .normal)
        }
        
        if viewModel.level.id == 10 { // PT
            buttonOutline.setTitle("PT Outline", for: .normal)
        }
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    func bindViewModel() {
        let input = SectionDetailViewModel.Input(firstLoadTrigger: rxViewWillAppear,
                                                 usefulLinkTapped: collectionView.rxModelSelected(),
                                                 buttonStartTrigger: buttonStart.rxButtonTapped,
                                                 buttonOutlineTrigger: buttonOutline.rxButtonTapped)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .usefulLinks
            .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource)),
         output
            .sectionDetail
            .drive(onNext: { [weak self] imageURL, sectionDetail in
               
                self?.labelSectionName.text = sectionDetail.name
                self?.sectionImageView.loadImage(with: imageURL, placeholder: #imageLiteral(resourceName: "img_drill"))
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
}
