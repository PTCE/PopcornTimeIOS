

import UIKit

class PCTLoadingViewAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    let sourceController: UIViewController
    
    init(isPresenting: Bool, sourceController source: UIViewController) {
        self.sourceController = source
        self.isPresenting = isPresenting
        super.init()
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.6
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning)  {
        if isPresenting {
            animatePresentationWithTransitionContext(transitionContext)
        }
        else {
            animateDismissalWithTransitionContext(transitionContext)
        }
    }
    
    
    func animatePresentationWithTransitionContext(transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentedControllerView = transitionContext.viewForKey(UITransitionContextToViewKey),
            let containerView = transitionContext.containerView()
            else {
                return
        }
        
        containerView.addSubview(presentedControllerView)
        presentedControllerView.hidden = true
        
        let view = UIView(frame: sourceController.view.bounds)
        view.backgroundColor = UIColor.blackColor()
        view.alpha = 0.0
        sourceController.view.addSubview(view)
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .AllowUserInteraction, animations: {
            if let sourceController = self.sourceController as? DetailItemOverviewViewController {
                sourceController.lastHeaderHeight = sourceController.headerHeightConstraint.constant
                let frame = sourceController.tabBarController?.tabBar.frame
                let nframe = sourceController.navigationController?.navigationBar.frame
                let offsetY = frame!.size.height
                let noffsetY = -(nframe!.size.height + sourceController.statusBarHeight())
                sourceController.tabBarController?.tabBar.frame = CGRectOffset(frame!, 0, offsetY)
                sourceController.navigationController?.navigationBar.frame = CGRectOffset(nframe!, 0, noffsetY)
                sourceController.progressiveness = 0.0
                sourceController.blurView.alpha = 0.0
                for view in sourceController.gradientViews {
                   view.alpha = 0.0
                }
                if let showDetail = self.sourceController as? TVShowDetailViewController {
                    showDetail.segmentedControl.alpha = 0.0
                }
                sourceController.headerHeightConstraint.constant = UIScreen.mainScreen().bounds.height
                sourceController.view.layoutIfNeeded()
                view.alpha = 0.4
            }
            }, completion: { completed in
                view.removeFromSuperview()
                self.sourceController.navigationController?.setNavigationBarHidden(true, animated: false)
                presentedControllerView.hidden = false
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
    
    func animateDismissalWithTransitionContext(transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentedControllerView = transitionContext.viewForKey(UITransitionContextFromViewKey),
            let presentingControllerView = transitionContext.viewForKey(UITransitionContextToViewKey),
            let containerView = transitionContext.containerView()
            else {
                return
        }
        containerView.addSubview(presentingControllerView)
        presentedControllerView.hidden = true
        sourceController.navigationController?.setNavigationBarHidden(false, animated: true)
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .AllowUserInteraction, animations: {
            if let sourceController = self.sourceController as? DetailItemOverviewViewController {
                sourceController.headerHeightConstraint.constant = sourceController.lastHeaderHeight
                sourceController.updateScrolling(true)
                if let showDetail = self.sourceController as? TVShowDetailViewController {
                    showDetail.segmentedControl.alpha = 1.0
                }
                for view in sourceController.gradientViews {
                    view.alpha = 1.0
                }
                let frame = sourceController.tabBarController?.tabBar.frame
                let offsetY = -frame!.size.height
                sourceController.tabBarController?.tabBar.frame = CGRectOffset(frame!, 0, offsetY)
            }
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
}
