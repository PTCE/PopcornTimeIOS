

import UIKit

class PCTEpisodeDetailPresentationController: UIPresentationController {
    
    var preferredContentHeight: CGFloat = 0
    
    lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.blackColor()
        let tap = UITapGestureRecognizer(target:self, action:#selector(dimmingViewTapped))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    func dimmingViewTapped(gesture: UIGestureRecognizer) {
        if gesture.state == .Recognized {
            presentingViewController.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    override func preferredContentSizeDidChangeForChildContentContainer(container: UIContentContainer) {
        super.preferredContentSizeDidChangeForChildContentContainer(container)
        preferredContentHeight = container.preferredContentSize.height
        containerViewWillLayoutSubviews()
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        dimmingView.frame = containerView!.bounds
        dimmingView.alpha = 0
        containerView?.insertSubview(dimmingView, atIndex: 0)
        presentedViewController.transitionCoordinator()?.animateAlongsideTransition({ [weak self] context in
            self?.dimmingView.alpha = 0.6
            }, completion: nil)
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentedViewController.transitionCoordinator()?.animateAlongsideTransition({ [weak self] context in
            self?.dimmingView.alpha = 0
            }, completion: nil)
    }
    
    override func frameOfPresentedViewInContainerView() -> CGRect {
        let screenSize = UIScreen.mainScreen().bounds.size
        if preferredContentHeight < screenSize.height {
            return CGRect(x: 0, y: screenSize.height - preferredContentHeight, width: containerView!.frame.width, height: preferredContentHeight)
        }
        
        return CGRect(origin: CGPointZero, size: screenSize)
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let bounds = containerView?.bounds {
            dimmingView.frame = bounds
            presentedView()?.frame = frameOfPresentedViewInContainerView()
        }
    }
}

class PCTEpisodeDetailPercentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition {
    var hasStarted = false
    var shouldFinish = false
}

class  PCTEpisodeDetailAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    let isPresenting: Bool
    
    init(isPresenting: Bool) {
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
            let presentedControllerView = transitionContext.viewForKey(UITransitionContextToViewKey)
            else {
                return
        }
        
        let containerView = transitionContext.containerView()
        containerView.addSubview(presentedControllerView)
        
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .AllowUserInteraction, animations: {
            presentedControllerView.frame.origin.y = -UIScreen.mainScreen().bounds.height
            }, completion: { completed in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
    
    func animateDismissalWithTransitionContext(transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentedControllerView = transitionContext.viewForKey(UITransitionContextFromViewKey)
            else {
                return
        }
        let containerView = transitionContext.containerView()
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .AllowUserInteraction, animations: {
            presentedControllerView.center.y += containerView.bounds.size.height
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
}
