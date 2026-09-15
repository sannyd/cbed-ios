//
//  TutorsSheetViewController.swift
//  CBED
//
//  Bottom sheet (UISheetPresentationController .medium / .large) showing all
//  users with `is_tutor = TRUE`. Each tutor is rendered with their avatar,
//  name, and last-known subject (lastSectionName). Bottom CTA opens a
//  pre-filled mailto to support@barexamdrills.com.
//
//  Data source: `ScoreboardResponseM.tutor` → [ScoreM]. The backend populates
//  this list from `users_user.is_tutor = TRUE`. Tutors are excluded from the
//  student ranking in the parent screen (see ScoreboardViewModel).
//

import UIKit
import RxSwift

final class TutorsSheetViewController: UIViewController {

    // MARK: - Data
    private let tutors: [ScoreM]
    private let bag = DisposeBag()

    // MARK: - Init
    init(tutors: [ScoreM]) {
        self.tutors = tutors
        super.init(nibName: nil, bundle: nil)
        title = "Tutors"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported — use init(tutors:)")
    }

    // MARK: - UI components
    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.alwaysBounceVertical = true
        s.showsVerticalScrollIndicator = false
        s.contentInset = .init(top: 0, left: 0, bottom: 24, right: 0)
        return s
    }()

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 12
        s.alignment = .fill
        s.distribution = .fill
        s.isLayoutMarginsRelativeArrangement = true
        s.layoutMargins = .init(top: 8, left: 20, bottom: 8, right: 20)
        return s
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Bar Exam Drills tutors with the full tutoring package. Tap below to request a session."
        l.font = .systemFont(ofSize: 13)
        l.textColor = Constants.ColorA2A2A2
        l.numberOfLines = 0
        return l
    }()

    private let ctaButton: UIButton = {
        let b = UIButton(type: .system)
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Request a tutoring session"
        cfg.baseBackgroundColor = Constants.PrimaryBlue
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.contentInsets = .init(top: 12, leading: 18, bottom: 12, trailing: 18)
        b.configuration = cfg
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.BackgroundColor
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )
        buildLayout()
        renderTutors()
    }

    // MARK: - Layout
    private func buildLayout() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        ctaButton.addTarget(self, action: #selector(requestTapped), for: .touchUpInside)
    }

    private func renderTutors() {
        contentStack.addArrangedSubview(subtitleLabel)

        if tutors.isEmpty {
            let empty = UILabel()
            empty.text = "No tutors available right now."
            empty.font = .systemFont(ofSize: 14)
            empty.textColor = Constants.ColorA2A2A2
            empty.textAlignment = .center
            empty.numberOfLines = 0
            contentStack.addArrangedSubview(empty)
        } else {
            for tutor in tutors {
                contentStack.addArrangedSubview(makeTutorCard(tutor))
            }
        }

        // CTA pinned at bottom of scroll content
        contentStack.setCustomSpacing(20, after: contentStack.arrangedSubviews.last ?? subtitleLabel)
        contentStack.addArrangedSubview(ctaButton)
    }

    private func makeTutorCard(_ tutor: ScoreM) -> UIView {
        let card = CustomBorderView()
        card.backgroundColor = Constants.CellColor
        card.setCornerRadius(radius: 14)
        card.setShadow(color: Constants.CardShadowColor, opacity: 0.18, radius: 6, offset: .init(width: 0, height: 2))

        let avatar = UIImageView()
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 26
        avatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 52),
            avatar.heightAnchor.constraint(equalToConstant: 52),
        ])
        avatar.backgroundColor = Constants.SecondarySurfaceColor
        if let avatarName = tutor.avatar, !avatarName.isEmpty {
            avatar.loadImage(with: avatarName, placeholder: #imageLiteral(resourceName: "img_user_placeholder"))
        } else {
            // Placeholder initial monogram
            let initial = (tutor.name?.first.map(String.init) ?? "T")
            avatar.image = UIImage.monogram(initial: initial,
                                            size: CGSize(width: 52, height: 52),
                                            background: Constants.SecondarySurfaceColor,
                                            text: Constants.PrimaryTextColor)
        }

        let nameLabel = UILabel()
        nameLabel.text = (tutor.name?.isEmpty == false) ? tutor.name : "Tutor #\(tutor.id)"
        nameLabel.font = .boldSystemFont(ofSize: 15)
        nameLabel.textColor = Constants.PrimaryTextColor
        nameLabel.numberOfLines = 1

        let badge = UILabel()
        badge.text = " Tutor "
        badge.font = .boldSystemFont(ofSize: 10)
        badge.textColor = .white
        badge.backgroundColor = Constants.PrimaryBlue
        badge.layer.cornerRadius = 4
        badge.clipsToBounds = true
        badge.setContentHuggingPriority(.required, for: .horizontal)
        badge.setContentCompressionResistancePriority(.required, for: .horizontal)

        let titleRow = UIStackView(arrangedSubviews: [nameLabel, badge])
        titleRow.axis = .horizontal
        titleRow.spacing = 6
        titleRow.alignment = .center

        let specialtyLabel = UILabel()
        let specialtyText = (tutor.lastSectionName?.isEmpty == false) ? tutor.lastSectionName : "Full bar prep"
        specialtyLabel.text = "Subject: \(specialtyText)"
        specialtyLabel.font = .systemFont(ofSize: 12)
        specialtyLabel.textColor = Constants.ColorA2A2A2
        specialtyLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleRow, specialtyLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading

        let row = UIStackView(arrangedSubviews: [avatar, textStack])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
        ])
        return card
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func requestTapped() {
        let subject = "Request a tutoring session"
        let body = "Hi Bar Exam Drills team,\n\nI'd like to request a tutoring session.\n\nThanks!"
        let urlString = "mailto:support@barexamdrills.com?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - UIImage monogram helper
private extension UIImage {
    static func monogram(initial: String,
                         size: CGSize,
                         background: UIColor,
                         text: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            background.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: text,
            ]
            let str = NSAttributedString(string: initial.uppercased(), attributes: attrs)
            let strSize = str.size()
            let origin = CGPoint(x: (size.width - strSize.width) / 2,
                                 y: (size.height - strSize.height) / 2)
            str.draw(at: origin)
        }
    }
}
