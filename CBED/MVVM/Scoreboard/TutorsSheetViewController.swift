//
//  TutorsSheetViewController.swift
//  CBED
//
//  Bottom sheet (UISheetPresentationController .medium / .large) showing all
//  users with `is_tutor_for_bed = TRUE`. Each tutor card displays the
//  tutor's avatar, name, and their current MBE level (from
//  `lastSectionName`). Read-only informational list.
//
//  Data source: `ScoreboardResponseM.tutor` → [ScoreM]. The backend populates
//  this list from `users_user.is_tutor_for_bed = TRUE` (per the
//  2026-09-15 tutor-flag unification: `/api/scoreboard-111`). Tutors are
//  excluded from the student ranking in the parent screen (see
//  ScoreboardViewModel).
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
        s.layoutMargins = .init(top: 16, left: 20, bottom: 16, right: 20)
        return s
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
    }

    private func renderTutors() {
        if tutors.isEmpty {
            let empty = UILabel()
            empty.text = "No tutors available right now."
            empty.font = .systemFont(ofSize: 14)
            empty.textColor = Constants.ColorA2A2A2
            empty.textAlignment = .center
            empty.numberOfLines = 0
            contentStack.addArrangedSubview(empty)
            return
        }

        for tutor in tutors {
            contentStack.addArrangedSubview(makeTutorCard(tutor))
        }
    }

    private func makeTutorCard(_ tutor: ScoreM) -> UIView {
        let card = CustomBorderView()
        card.backgroundColor = Constants.CellColor
        card.setCornerRadius(radius: 14)
        card.setShadow(color: Constants.CardShadowColor, opacity: 0.18, offSet: .init(width: 0, height: 2), radius: 6)

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

        // Subtitle is the tutor's current MBE level. Unwrap the optional
        // explicitly with `if let` so Swift's debug `Optional(...)`
        // description can never leak into the UI. Empty -> "Level 1" so
        // a brand-new tutor without section history still shows
        // something readable (matches user request).
        let levelLabel = UILabel()
        if let sectionName = tutor.lastSectionName, !sectionName.isEmpty {
            levelLabel.text = sectionName
        } else {
            levelLabel.text = "Level 1"
        }
        levelLabel.font = .systemFont(ofSize: 12)
        levelLabel.textColor = Constants.ColorA2A2A2
        levelLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [nameLabel, levelLabel])
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
