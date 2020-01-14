import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var trackerNode: SCNNode?
    var foundSurface = false
    var tracking = true
    var directionalLightNode: SCNNode?
    var ambientLightNode: SCNNode?
    var container: SCNNode!
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard tracking else { return }
        let hitTest = self.sceneView.hitTest(CGPoint(x: self.view.frame.midX, y: self.view.frame.midY), types: .featurePoint)
        //if hittest failed, return
        guard let result = hitTest.first else { return }
        let translation = SCNMatrix4(result.worldTransform)
        let position = SCNVector3Make(translation.m41, translation.m42, translation.m43)
        
        //set trackerNode
        if trackerNode == nil {
            let plane = SCNPlane(width: 0.15, height: 0.15)
            plane.firstMaterial?.diffuse.contents = UIImage(named: "tracker.png")
            plane.firstMaterial?.isDoubleSided = true
            trackerNode = SCNNode(geometry: plane)
            trackerNode?.eulerAngles.x = -.pi * 0.5
            self.sceneView.scene.rootNode.addChildNode(self.trackerNode!)
            foundSurface = true
        }
        self.trackerNode?.position = position 
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if tracking {
            //Set up the scene
            guard foundSurface else { return }
            let trackingPosition = trackerNode!.position
            trackerNode?.removeFromParentNode()
            container = sceneView.scene.rootNode.childNode(withName: "container", recursively: false)!
            container.position = trackingPosition
            container.isHidden = false
            ambientLightNode = container.childNode(withName: "ambientLight", recursively: false)
            directionalLightNode = container.childNode(withName: "directionalLight", recursively: false)
            sceneView.scene.physicsWorld.contactDelegate = self
            tracking = false
        } else {
            //Handle the shooting
            guard let frame = sceneView.session.currentFrame else { return }
            let camMatrix = SCNMatrix4(frame.camera.transform)
            let direction = SCNVector3Make(-camMatrix.m31 * 5.0, -camMatrix.m32 * 0.0, -camMatrix.m33 * 5.0)
            let position = SCNVector3Make(camMatrix.m41, camMatrix.m42, camMatrix.m43)
            
            let ball = SCNSphere(radius: 0.1)
            ball.firstMaterial?.diffuse.contents = UIColor.blue
            ball.firstMaterial?.emission.contents = UIColor.green
            ball.firstMaterial?.metalness.contents = NSNumber(1)
            let ballNode = SCNNode(geometry: ball)
            ballNode.position = position
            ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            ballNode.physicsBody?.categoryBitMask = 3
            ballNode.physicsBody?.contactTestBitMask = 1
            sceneView.scene.rootNode.addChildNode(ballNode)
            ballNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 5.0), SCNAction.removeFromParentNode()]))
            ballNode.physicsBody?.applyForce(direction, asImpulse: true)
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let lightEstimate = frame.lightEstimate else { return }
        guard !tracking else { return }
        ambientLightNode?.light?.intensity = lightEstimate.ambientIntensity * 0.4
        directionalLightNode?.light?.intensity = lightEstimate.ambientIntensity
    }
    
    //collision happened
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
       // let ball = contact.nodeA.physicsBody!.contactTestBitMask == 3 ? contact.nodeA : contact.nodeB
        //let explosion = SCNParticleSystem(named: "Explosion.scnp", inDirectory: nil)!
        //let explosionNode = SCNNode()
        //set explosion at collission position
        //explosionNode.position = ball.presentation.position
        //sceneView.scene.rootNode.addChildNode(explosionNode)
        //explosionNode.addParticleSystem(explosion)
        //ball.removeFromParentNode()
        let cone = contact.nodeB
        cone.runAction(SCNAction.sequence([SCNAction.wait(duration: 2.0), SCNAction.removeFromParentNode()]))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/scene.scn")!
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        sceneView.session.delegate = self
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
