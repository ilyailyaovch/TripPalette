import SwiftUI
import UIKit

/// Перехватывает повторный тап по уже выбранной вкладке TabView,
/// чтобы вместо системного scroll-to-top вызвать свой обработчик.
struct TPTabBarReselectHandler: UIViewControllerRepresentable {
    var onReselect: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onReselect: onReselect)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.onReselect = onReselect
        DispatchQueue.main.async {
            guard let tabBarController = uiViewController.tabBarController else { return }
            if tabBarController.delegate !== context.coordinator {
                context.coordinator.forwardingDelegate = tabBarController.delegate
                tabBarController.delegate = context.coordinator
            }
        }
    }

    final class Coordinator: NSObject, UITabBarControllerDelegate {
        var onReselect: (Int) -> Void
        weak var forwardingDelegate: UITabBarControllerDelegate?

        init(onReselect: @escaping (Int) -> Void) {
            self.onReselect = onReselect
        }

        func tabBarController(
            _ tabBarController: UITabBarController,
            shouldSelect viewController: UIViewController
        ) -> Bool {
            if tabBarController.selectedViewController === viewController,
               let index = tabBarController.viewControllers?.firstIndex(of: viewController)
            {
                onReselect(index)
                return false
            }

            return forwardingDelegate?.tabBarController?(
                tabBarController,
                shouldSelect: viewController
            ) ?? true
        }

        func tabBarController(
            _ tabBarController: UITabBarController,
            didSelect viewController: UIViewController
        ) {
            forwardingDelegate?.tabBarController?(tabBarController, didSelect: viewController)
        }
    }
}
