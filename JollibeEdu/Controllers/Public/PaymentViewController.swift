//
//  PaymentViewController.swift
//  JollibeEdu
//
//  Created by Nguyễn Hoàng Quân on 22/3/26.
//

import UIKit
import CoreImage.CIFilterBuiltins

final class PaymentViewController: BaseStackContainerViewController {
    override var clearsInitialStoryboardContent: Bool { false }

    var course: Course?
    var courseID: String?

    private let selectorView = PaymentMethodSelectorView()
    @IBOutlet private weak var headerCardView: UIView!
    @IBOutlet private weak var summaryCardView: UIView!
    @IBOutlet private weak var summaryLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var selectorContainerView: UIView!
    @IBOutlet private weak var bankCardView: UIView!
    @IBOutlet private weak var cardNumberField: UITextField!
    @IBOutlet private weak var cardHolderField: UITextField!
    @IBOutlet private weak var expiryField: UITextField!
    @IBOutlet private weak var cvvField: UITextField!
    @IBOutlet private weak var momoCardView: UIView!
    @IBOutlet private weak var momoAccountNameLabel: UILabel!
    @IBOutlet private weak var momoAccountNumberLabel: UILabel!
    @IBOutlet private weak var momoQRImageView: UIImageView!
    @IBOutlet private weak var momoInstructionLabel: UILabel!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var stateLabel: UILabel!

    private let qrContext = CIContext()
    private let qrFilter = CIFilter.qrCodeGenerator()
    private let momoReceiverName = "NGUYEN HOANG QUAN"
    private let momoReceiverAccountNumber = "1000 3565 742"

    override func buildContent() {
        title = L10n.tr("payment.title")
        navigationItem.largeTitleDisplayMode = .never

        headerCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        summaryCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        bankCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        momoCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        summaryLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        summaryLabel.textColor = AppTheme.textPrimary
        summaryLabel.numberOfLines = 0

        amountLabel.font = UIFont.boldSystemFont(ofSize: 30)
        amountLabel.textColor = AppTheme.brandOrangeDark

        stateLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        stateLabel.textColor = AppTheme.textSecondary
        stateLabel.numberOfLines = 0

        momoAccountNameLabel.font = UIFont.boldSystemFont(ofSize: 22)
        momoAccountNameLabel.textColor = AppTheme.textPrimary
        momoAccountNameLabel.textAlignment = .center
        momoAccountNameLabel.text = momoReceiverName

        momoAccountNumberLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        momoAccountNumberLabel.textColor = AppTheme.textSecondary
        momoAccountNumberLabel.textAlignment = .center
        momoAccountNumberLabel.text = momoReceiverAccountNumber

        momoQRImageView.contentMode = .scaleAspectFit
        momoQRImageView.backgroundColor = .white
        momoQRImageView.layer.cornerRadius = 16
        momoQRImageView.layer.masksToBounds = true

        momoInstructionLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        momoInstructionLabel.textColor = AppTheme.textSecondary
        momoInstructionLabel.numberOfLines = 0
        momoInstructionLabel.text = L10n.tr("payment.qr.instructions.default")

        cardNumberField.applyAppStyle(placeholder: L10n.tr("payment.field.cardNumber"), keyboard: .numberPad)
        cardHolderField.applyAppStyle(placeholder: L10n.tr("payment.field.cardHolder"))
        expiryField.applyAppStyle(placeholder: L10n.tr("payment.field.expiry"))
        cvvField.applyAppStyle(placeholder: L10n.tr("payment.field.cvv"), secure: true, keyboard: .numberPad)

        selectorView.onMethodChanged = { [weak self] _ in
            self?.updateMethodUI()
        }
        embedSelectorView()

        confirmButton.applyPrimaryStyle()
        confirmButton.setTitle(L10n.tr("payment.confirm"), for: .normal)
        confirmButton.addAction(UIAction { [weak self] _ in
            self?.confirmPayment()
        }, for: .touchUpInside)

        Task {
            await loadCourseInfo()
        }
    }

    private func embedSelectorView() {
        guard selectorView.superview !== selectorContainerView else { return }
        selectorView.removeFromSuperview()
        selectorContainerView.subviews.forEach { $0.removeFromSuperview() }
        selectorView.translatesAutoresizingMaskIntoConstraints = false
        selectorContainerView.addSubview(selectorView)
        NSLayoutConstraint.activate([
            selectorView.topAnchor.constraint(equalTo: selectorContainerView.topAnchor),
            selectorView.leadingAnchor.constraint(equalTo: selectorContainerView.leadingAnchor),
            selectorView.trailingAnchor.constraint(equalTo: selectorContainerView.trailingAnchor),
            selectorView.bottomAnchor.constraint(equalTo: selectorContainerView.bottomAnchor)
        ])
    }

    private func loadCourseInfo() async {
        do {
            if course == nil, let courseID {
                course = try await CourseService.shared.getById(id: courseID)
            }
            guard let course else { return }
            summaryLabel.text = L10n.tr("payment.summary", course.displayTitle, course.instructor_name ?? L10n.tr("course.detail.fallbackInstructorName"))
            amountLabel.text = course.formattedPrice
            renderQRCode(for: course)
            updateMethodUI()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func updateMethodUI() {
        let method = selectorView.selectedMethod
        bankCardView.isHidden = method != .bankCard
        momoCardView.isHidden = method != .momo
    }

    private func confirmPayment() {
        guard let course else { return }
        confirmButton.isEnabled = false
        confirmButton.setTitle(L10n.tr("payment.loading"), for: .normal)
        stateLabel.textColor = AppTheme.textSecondary
        stateLabel.text = L10n.tr("payment.processing")

        Task { @MainActor in
            defer {
                confirmButton.isEnabled = true
                confirmButton.setTitle(L10n.tr("payment.confirm"), for: .normal)
            }

            do {
                let payment = try await PaymentService.shared.create(courseId: course.id, method: selectorView.selectedMethod.rawValue)
                _ = try await PaymentService.shared.confirm(paymentId: payment.id)
                stateLabel.textColor = AppTheme.successGreen
                stateLabel.text = L10n.tr("payment.success.state")
                showSuccess(message: L10n.tr("payment.success.alert")) { [weak self] in
                    guard let self else { return }
                    let controller: LessonListViewController = RootRouter.shared.instantiate(identifier: "LessonListViewController")
                    controller.course = course
                    navigationController?.pushViewController(controller, animated: true)
                }
            } catch {
                stateLabel.textColor = AppTheme.dangerRed
                stateLabel.text = error.localizedDescription
            }
        }
    }

    private func renderQRCode(for course: Course) {
        let learnerName = SessionManager.shared.currentUser?.displayName ?? momoReceiverName
        let paymentContent = "\(course.displayTitle) - \(learnerName)"
        let payload = [
            "bank=MB",
            "receiver=\(momoReceiverName)",
            "account=\(momoReceiverAccountNumber.replacingOccurrences(of: " ", with: ""))",
            "course_id=\(course.id)",
            "amount=\(course.price ?? 0)",
            "content=\(paymentContent)"
        ].joined(separator: "|")

        qrFilter.setValue(Data(payload.utf8), forKey: "inputMessage")
        qrFilter.setValue("M", forKey: "inputCorrectionLevel")

        momoInstructionLabel.text = L10n.tr(
            "payment.qr.instructions",
            paymentContent
        )

        guard let outputImage = qrFilter.outputImage else {
            momoQRImageView.image = UIImage(systemName: "qrcode")
            return
        }

        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = qrContext.createCGImage(scaled, from: scaled.extent) else {
            momoQRImageView.image = UIImage(systemName: "qrcode")
            return
        }

        momoQRImageView.image = UIImage(cgImage: cgImage)
    }
}
